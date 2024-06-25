import flask

import whoami.index

class WhoAmI(flask.Flask):
    def __init__(self, name, **kwargs):
        super().__init__(name, **kwargs)

def create_app(**kwargs):
    app = WhoAmI(__name__, **kwargs)
    app.register_blueprint(whoami.index.bp)

    return app
