"""Loopback HTTP fixture for Chromium's production reachability adapter test.

No app API/business implementation: only health responses, transport failure and
probe metadata. Run alongside tool/web_test.sh, never in a deployed service.
"""

import argparse
import json
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import ClassVar


class Fixture(BaseHTTPRequestHandler):
    mode = "ok"
    probes: ClassVar[list[dict[str, object]]] = []

    def log_message(self, format: str, *args: object) -> None:
        pass

    def respond(self, status: int, data: object) -> None:
        payload = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Cache-Control")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_OPTIONS(self) -> None:
        self.respond(200, {})

    def do_GET(self) -> None:
        if self.path == "/test/probes":
            self.respond(200, Fixture.probes)
            return
        if self.path != "/v1/health":
            self.respond(404, {})
            return
        Fixture.probes.append(
            {
                "method": "GET",
                "path": self.path,
                "has_authorization": bool(self.headers.get("Authorization")),
                "has_device_id": bool(self.headers.get("X-Device-ID")),
                "body_size": int(self.headers.get("Content-Length", "0")),
            }
        )
        if Fixture.mode == "disconnect":
            self.connection.shutdown(socket.SHUT_RDWR)
            self.connection.close()
        elif Fixture.mode == "portal":
            self.respond(200, {"login": "captive portal, not API health"})
        else:
            self.respond(
                200 if Fixture.mode == "ok" else 503,
                {"status": "ok" if Fixture.mode == "ok" else "unhealthy"},
            )

    def do_POST(self) -> None:
        if self.path != "/test/state":
            self.respond(404, {})
            return
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
        Fixture.mode = body["mode"]
        if body.get("reset"):
            Fixture.probes.clear()
        self.respond(200, {})


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8766)
    args = parser.parse_args()
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Fixture)
    print(f"Reachability fixture ready on {args.port}", flush=True)
    server.serve_forever()
