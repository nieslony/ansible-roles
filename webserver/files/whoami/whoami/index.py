import flask
import os
import ldap3
import configparser
import gssapi

bp = flask.Blueprint("index", __name__)

def krb5ccname():
    return flask.request.environ.get("KRB5CCNAME") if flask.request.environ.get("KRB5CCNAME") else os.environ.get("KRB5CCNAME")

@bp.route("/")
@bp.route("/index.html")
def index():
    sorted_env = sorted(flask.request.environ.items())
    return flask.render_template(
        "index.html",
        env=sorted_env,
        env_dict=flask.request.environ,
        remote_user=flask.request.environ.get("REMOTE_USER"),
        krb5ccname=krb5ccname()
        )

@bp.route("/ldap_search.html")
def ldap_search():
    try:
        cfg = configparser.ConfigParser()
        cfg.read("/etc/ipa/default.conf")
        server_url = f"ldap://{cfg['global']['server']}"
        base_dn = cfg['global']['basedn']
    except Exception:
        server_url = "ldap://ldap.example.com"
        base_dn = "dc=example,dc=com"
    username = flask.request.environ.get("REMOTE_USER") if flask.request.environ.get("REMOTE_USER") else os.getlogin()
    search = f"(&(uid={username})(objectclass=person))" if username.find("@") == -1 else f"(&(krbPrincipalName={username})(objectclass=person))"
    result = None
    return flask.render_template(
        "ldap_search.html",
        server_url=server_url,
        base_dn=base_dn,
        search=search,
        result=result
        )

def do_ldap_search(server_url, base_dn, search):
    if flask.request.environ.get("KRB5CCNAME") and not  os.environ.get("KRB5CCNAME"):
        ccname = flask.request.environ.get("KRB5CCNAME")
        print(f"Setting credential cache {ccname}")
        os.environ["KRB5CCNAME"] = ccname
    server = ldap3.Server(server_url)
    connection = ldap3.Connection(server, authentication = ldap3.SASL, sasl_mechanism=ldap3.KERBEROS)
    connection.bind()
    connection.search(search_base=base_dn, search_filter=search, attributes=ldap3.ALL_ATTRIBUTES)
    return connection.response

@bp.route("/ldap_search.html", methods=["POST"])
def post_ldap_search():
    server_url = flask.request.form.get("server_url")
    base_dn = flask.request.form.get("base_dn")
    search = flask.request.form.get("search")
    error = None
    result = None
    try:
        result = do_ldap_search(server_url, base_dn, search)
    except ldap3.core.exceptions.LDAPException as ex:
        error = ex
    except gssapi.raw.exceptions.GSSError as ex:
        error = ex

    return flask.render_template(
        "ldap_search.html",
        server_url=server_url,
        base_dn=base_dn,
        search=search,
        result=result,
        error=error
        )
