#!/usr/bin/python3

import flask
import ldap3
import configparser
import toml
import ssl
import logging
import os
from logging.config import dictConfig

class AutoconfigApp(flask.Flask):
    CFG_FILE = f"{os.path.dirname(__file__)}/autoconfig.ini"

    def __init__(self, loglevel):
        super().__init__(__name__)

        #self.logger.setLevel(loglevel)

        config = toml.load(AutoconfigApp.CFG_FILE)
        self.config.update(config)

    def create_ldap_connection(self):
        con = None

        hosts = self.config["ldap"]["ldap_server"]
        for host in hosts:
            self.logger.info(f"Try to bind to {host}")
            try:
                if self.config["ldap"]["ignore_cert_errors"]:
                    self.logger.info("Ignoring SSL errors")
                    tls = ldap3.Tls(validate=ssl.CERT_NONE, version=ssl.PROTOCOL_TLSv1_2)
                else:
                    self.logger.info("Require tls 1.2")
                    tls = ldap3.Tls(version=ssl.PROTOCOL_TLSv1_2)
                server = ldap3.Server(host, use_ssl=True, tls=tls)

                if self.config["ldap"]["authentication"] == "simple":
                    self.logger.info("LDAP simple bind")
                    con = ldap3.Connection(
                        server,
                        user=self.config["ldap"]["simple_bind_dn"],
                        password=self.config["ldap"]["simple_bind_password"]
                        )
                elif self.config["ldap"]["authentication"] == "GSSAPI":
                    client_keytab = self.config["ldap"]["client_keytab"]
                    self.logger.info(f"LDAP GSSAPI bind with keytab {client_keytab}")
                    os.environ["KRB5_CLIENT_KTNAME"] = client_keytab
                    con = ldap3.Connection(
                        server,
                        authentication=ldap3.SASL,
                        sasl_mechanism=ldap3.KERBEROS
                        )
                else:
                    self.logger.error(f"Cannot bind to LDAP server {host}")

                if con.bind():
                    self.logger.info(f"Bound as {con.extend.standard.who_am_i()}")
                    break
                else:
                    self.logger.error(f"Cannot bind to LDAP server {host}")
            except ldap3.core.exceptions.LDAPSocketOpenError as ex:
                self.logger.warning(str(ex))
                pass

        if con == None:
            flask.abort("Cannot connect to LDAP server", 404)
        return con

def create_app(loglevel=logging.ERROR):
    app = AutoconfigApp(loglevel)

    @app.route("/config-v1.1.xml")
    def autoconfig_xml():
        username = flask.request.environ.get("REMOTE_USER")
        if username is None or username == "":
            return "No remote user provided", 401

        con = app.create_ldap_connection()
        base_dn = app.config["ldap"]["base_dn"]
        ldap_filter = app.config["ldap"]["filter"].format(username=username)
        app.logger.info(f"LDAP filter: {ldap_filter}")

        if con.search(base_dn, ldap_filter, search_scope=ldap3.SUBTREE, attributes=["displayname", "mail"]):
            attrs = con.response[0]["attributes"]
            app.logger.info(f"Found attrs for user {username}: {str(attrs)}")
            args = {
                "maildomain": app.config["servers"]["maildomain"],
                "mailserver": app.config["servers"]["mailserver"],
                "organization": app.config["servers"]["organization"],
                "mail": attrs["mail"][0],
                "displayname": attrs["displayname"]
                }
        else:
            return "Not found", 404

        return flask.render_template("config-v1.1.xml", **args)

    return app

def main():
    app = create_app(logging.DEBUG)
    app.config.ENV = "development"
    app.config.DEBUG = True
    app.logger.info("Created app from main function")
    app.run()

if __name__ == "__main__":
    dictConfig({
        'version': 1,
        'formatters': {'default': {
            'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
        }},
        'handlers': {'wsgi': {
            'class': 'logging.StreamHandler',
            'stream': 'ext://flask.logging.wsgi_errors_stream',
            'formatter': 'default'
        }},
        'root': {
            'level': 'INFO',
            'handlers': ['wsgi']
        }
    })
    # run from command line
    main()
else:
    # run from wsgi
    dictConfig({
        'version': 1,
        'formatters': {'default': {
            'format': '%(levelname)s in %(module)s: %(message)s',
        }},
        'handlers': {'wsgi': {
            'class': 'logging.StreamHandler',
            'stream': 'ext://flask.logging.wsgi_errors_stream',
            'formatter': 'default'
        }},
        'root': {
            'level': 'INFO',
            'handlers': ['wsgi']
        }
    })
    application = create_app()
