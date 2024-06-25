import flask

bp = flask.Blueprint("index", __name__)

@bp.route("/")
def index():
    return "Hallo"
