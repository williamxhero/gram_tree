"""Operator recovery/cleanup interface: python -m gramtree.exports run|cleanup."""

import argparse
import json
from datetime import datetime

from gramtree.core.time import utcnow
from gramtree.db import make_engine, make_session_factory
from gramtree.exports import service
from gramtree.settings import get_settings


def main() -> None:
    parser = argparse.ArgumentParser(description="Drain durable exports or remove expired archives")
    parser.add_argument("action", choices=["run", "cleanup"])
    parser.add_argument("--as-of", type=datetime.fromisoformat, default=None)
    args = parser.parse_args()
    now = args.as_of or utcnow()
    if now.tzinfo is None:
        parser.error("--as-of requires a timezone")
    settings = get_settings()
    with make_session_factory(make_engine(settings.database_url))() as session:
        result = getattr(service, args.action)(session, settings, now)
    print(json.dumps(result))


if __name__ == "__main__":
    main()
