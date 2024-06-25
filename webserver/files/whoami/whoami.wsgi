#!/usr/bin/python3

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

import whoami

def main():
    parser = argparse.ArgumentParser(description="Start baustelle from command line")
    parser.add_argument("--environment", "-e",
                        help="Flask environment",
                        default="production",
                        choices=["production", "development"]
                        )
    parser.add_argument("--listen", "-l",
                        help="Listen on given IP address",
                        default="localhost"
                        )
    parser.add_argument("--port", "-p",
                        help="TCP to listen on",
                        default=5000,
                        type=int,
                        )
    args = parser.parse_args()

    os.environ["FLASK_ENV"] = args.environment

    app = whoami.create_app()
    app.logger.info("Created app from main function")
    app.run(host=args.listen, port=args.port)

if __name__ == "__main__":
    main()
else:
    application = whoami.create_app()
