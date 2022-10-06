#!/usr/bin/python3

import flask
import ldap3
import configparser
import toml
import ssl
import logging
import os

class AutoconfigApp(flask.Flask):
    CFG_FILE = f"{os.path.dirname(__file__)}/autoconfig.ini"

    def __init__(self, loglevel):
        super().__init__(__name__)

        self.logger.setLevel(loglevel)

        config = toml.load(AutoconfigApp.CFG_FILE)
        self.config.update(config)

    def create_ldap_connection(self):
        con = None

        hosts = self.config["ldap"]["ldap_server"]
        for host in hosts:
            self.logger.info(f"Try to bind to {host}")
            try:
                if self.config["ldap"]["ignore_cert_errors"]:
                    tls = ldap3.Tls(validate=ssl.CERT_NONE, version=ssl.PROTOCOL_TLSv1_2)
                else:
                    tls = ldap3.Tls(version=ssl.PROTOCOL_TLSv1_2)
                server = ldap3.Server(host, use_ssl=True, tls=tls)
                if self.config["ldap"]["authentication"] == "simple":
                    con = ldap3.Connection(server,
                                            user=self.config["ldap"]["simple_bind_dn"],
                                            password=self.config["ldap"]["simple_bind_password"]
                                            )
                elif self.config["ldap"]["authentication"] == "GSSAPI":
                    os.environ["KRB5_CLIENT_KTNAME"] = self.config["ldap"]["client_keytab"]
                    con = ldap3.Connection(server, authentication=ldap3.SASL, sasl_mechanism=ldap3.KERBEROS)
                else:
                    self.logger.error(f"Cannot bind to LDAP server {host}")
                if con.bind():
                    self.logger.info(f"Bound as {con.extend.standard.who_am_i()}")
                    break
                else:
                    self.logger.error(f"Cannot bind to LDAP server {host}")
            except ldap3.core.exceptions.LDAPSocketOpenError:
                pass

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
        ldap_filter = f"(uid={username})"

        if con.search(base_dn, ldap_filter, search_scope=ldap3.SUBTREE, attributes=["displayname", "mail"]):
            attrs = con.response[0]["attributes"]
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
    # run from command line
    main()
else:
    # run from wsgi
    application = create_app()
