import flask

bp = flask.Blueprint("index", __name__)

@bp.route("/")
def index():
    sorted_env = sorted(flask.request.environ.items())
    return flask.render_template(
        "index.html",
        env=flask.request.environ,
        remote_user=flask.request.environ.get("REMOTE_USER")
        )
