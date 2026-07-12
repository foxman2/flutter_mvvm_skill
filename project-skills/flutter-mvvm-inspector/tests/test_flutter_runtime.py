from __future__ import annotations

import json
import os
import signal
import subprocess
import sys
import tempfile
import textwrap
import threading
import time
import unittest
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


HELPER = Path(__file__).resolve().parents[1] / "scripts/flutter_runtime.py"
SECRET = "fixture-vm-secret"
FAKE_FLUTTER = r"""
import json, os, signal, sys, time
from pathlib import Path

args = sys.argv[1:]
pid_file = Path(next(x.split("=", 1)[1] for x in args if x.startswith("--pid-file=")))
vm_file = Path(next(x.split("=", 1)[1] for x in args if x.startswith("--vmservice-out-file=")))
with Path(os.environ["FAKE_LAUNCHES"]).open("a") as output:
    output.write(json.dumps({"pid": os.getpid(), "args": args}) + "\n")
pid_file.write_text(str(os.getpid()) + "\n")
running = True
def stop(*_):
    global running
    running = False
signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)
if hasattr(signal, "SIGHUP"):
    signal.signal(signal.SIGHUP, signal.SIG_IGN)
print("launch " + os.environ.get("FAKE_LABEL", "fixture"), flush=True)
time.sleep(float(os.environ.get("FAKE_READY_DELAY", "0")))
print("VM: " + os.environ["FAKE_HTTP_URI"], flush=True)
print("DevTools: " + os.environ["FAKE_WS_URI"], flush=True)
vm_file.write_text(os.environ["FAKE_WS_URI"] + "\n")
while running:
    time.sleep(0.03)
"""


class VMHandler(BaseHTTPRequestHandler):
    paths = []
    requests = []
    vm_isolates = []
    isolates = {}
    summary = None
    summary_as_json = False
    show_enabled = "true"

    def send_json(self, payload):
        body = json.dumps(payload).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802
        handler = type(self)
        handler.paths.append(self.path)
        parts = urllib.parse.urlsplit(self.path)
        method = parts.path.rsplit("/", 1)[-1]
        query = {
            key: values[-1]
            for key, values in urllib.parse.parse_qs(parts.query).items()
        }
        handler.requests.append({"method": method, "query": query})
        if method == "getVM":
            result = {"type": "VM", "isolates": handler.vm_isolates}
        elif method == "getIsolate":
            isolate_id = query.get("isolateId")
            if isolate_id not in handler.isolates:
                self.send_json({
                    "jsonrpc": "2.0",
                    "error": {"code": 105, "message": "isolate not found"},
                })
                return
            result = handler.isolates[isolate_id]
        elif method == "ext.flutter.inspector.show":
            result = {
                "type": "_extensionType",
                "method": method,
                "enabled": handler.show_enabled,
            }
        elif method == "ext.flutter.inspector.getSelectedSummaryWidget":
            value = handler.summary
            if handler.summary_as_json:
                value = json.dumps(value)
            result = {"type": "_extensionType", "method": method, "result": value}
        else:
            self.send_json({
                "jsonrpc": "2.0",
                "error": {"code": -32601, "message": "method not found"},
            })
            return
        self.send_json({"jsonrpc": "2.0", "result": result})

    def log_message(self, _format, *_args):
        pass


class FlutterRuntimeTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.project = Path(self.temp.name)
        (self.project / "pubspec.yaml").write_text("name: fixture\n")
        fake_bin = self.project / "bin"
        fake_bin.mkdir()
        flutter = fake_bin / "flutter"
        flutter.write_text(f"#!{sys.executable}\n{textwrap.dedent(FAKE_FLUTTER).lstrip()}")
        flutter.chmod(0o755)
        self.flutter = flutter
        self.launches = self.project / "launches.jsonl"
        self.runtime = self.project / ".dart_tool/flutter-mvvm-inspector"
        self.decoys = []
        VMHandler.paths = []
        VMHandler.requests = []
        VMHandler.vm_isolates = []
        VMHandler.isolates = {}
        VMHandler.summary = None
        VMHandler.summary_as_json = False
        VMHandler.show_enabled = "true"
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), VMHandler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        port = self.server.server_address[1]
        self.http_uri = f"http://127.0.0.1:{port}/{SECRET}=/"
        self.ws_uri = f"ws://127.0.0.1:{port}/{SECRET}=/ws"
        self.env = os.environ | {
            "PATH": str(fake_bin) + os.pathsep + os.environ.get("PATH", ""),
            "FAKE_LAUNCHES": str(self.launches),
            "FAKE_HTTP_URI": self.http_uri,
            "FAKE_WS_URI": self.ws_uri,
            "PYTHONUNBUFFERED": "1",
        }

    def tearDown(self):
        try:
            self.cli("stop")
        except (OSError, subprocess.SubprocessError):
            pass
        for process in self.decoys:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=1)
        for record in self.records():
            try:
                os.kill(record["pid"], signal.SIGTERM)
            except (ProcessLookupError, PermissionError):
                pass
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=1)
        self.temp.cleanup()

    def cli(self, *args, env=None, check=True):
        result = subprocess.run(
            [sys.executable, str(HELPER), *args], cwd=self.project,
            env=self.env if env is None else env, text=True, capture_output=True, timeout=5,
        )
        if check:
            self.assertEqual(0, result.returncode, result.stderr)
        return result

    def status(self):
        return self.cli("status").stdout.strip()

    def start(self, env=None):
        return self.cli("start", "--", "-d", "fixture-device", env=env)

    def wait_running(self):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if self.status() == "running":
                return
            time.sleep(0.04)
        self.fail("status did not become running")

    def records(self):
        if not self.launches.exists():
            return []
        return [json.loads(line) for line in self.launches.read_text().splitlines()]

    def test_lifecycle_recovery_reuse_endpoint_and_scoped_stop(self):
        self.assertEqual("not_started", self.status())
        self.assertNotEqual(0, self.cli("start", "--", "--release", check=False).returncode)
        slow = self.env | {"FAKE_READY_DELAY": "0.4"}
        self.assertEqual("starting", self.start(slow).stdout.strip())
        self.assertEqual("starting", self.status())
        self.wait_running()
        args = self.records()[0]["args"]
        for value in ("run", "--debug", "--track-widget-creation", "-d", "fixture-device"):
            self.assertIn(value, args)
        pid_path = next(x.split("=", 1)[1] for x in args if x.startswith("--pid-file="))
        vm_path = next(x.split("=", 1)[1] for x in args if x.startswith("--vmservice-out-file="))
        self.assertEqual((self.runtime / "flutter.pid").resolve(), Path(pid_path).resolve())
        self.assertEqual((self.runtime / "vmservice.ws").resolve(), Path(vm_path).resolve())
        for name in ("state.json", "flutter.pid", "vmservice.ws", "flutter.log"):
            self.assertTrue((self.runtime / name).is_file())
        self.assertEqual("running", self.cli("status", env=os.environ.copy()).stdout.strip())
        self.assertEqual(self.http_uri, self.cli("endpoint").stdout.strip())
        self.assertIn(f"/{SECRET}=/getVM", VMHandler.paths)
        self.assertEqual("running", self.start().stdout.strip())
        self.assertEqual(1, len(self.records()))

        decoy = subprocess.Popen(
            [str(self.flutter), "run", f"--pid-file={self.project / 'decoy.pid'}",
             f"--vmservice-out-file={self.project / 'decoy.ws'}"],
            cwd=self.project, env=self.env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        self.decoys.append(decoy)
        time.sleep(0.1)
        self.assertEqual("stopped", self.cli("stop").stdout.strip())
        self.assertEqual("stopped", self.status())
        self.assertIsNone(decoy.poll())
        self.assertTrue((self.runtime / "flutter.log").exists())
        state_path = self.runtime / "state.json"
        state = json.loads(state_path.read_text())
        state.update(pid=decoy.pid, status="running")
        state_path.write_text(json.dumps(state))
        (self.runtime / "flutter.pid").write_text(str(decoy.pid))
        self.cli("stop")
        self.assertIsNone(decoy.poll(), "stale PID identity must never be signalled")

    def test_logs_tail_rotate_and_redact(self):
        self.start(self.env | {"FAKE_LABEL": "first"})
        self.wait_running()
        logs = self.cli("logs").stdout
        self.assertIn("launch first", logs)
        self.assertNotIn(SECRET, logs)
        self.cli("stop")
        with (self.runtime / "flutter.log").open("a") as output:
            output.write("preserved first tail\n")
        self.start(self.env | {"FAKE_LABEL": "second"})
        self.wait_running()
        self.assertIn("preserved first tail", (self.runtime / "flutter.log.1").read_text())
        self.assertFalse((self.runtime / "flutter.log.2").exists())
        merged = self.cli("logs").stdout
        self.assertIn("launch first", merged)
        self.assertIn("launch second", merged)
        self.assertNotIn(SECRET, merged)
        self.cli("stop")
        lines = [f"line-{index:03d}" for index in range(260)]
        (self.runtime / "flutter.log.1").write_text("\n".join(lines[:30]) + "\n")
        (self.runtime / "flutter.log").write_text("\n".join(lines[30:]) + "\n")
        self.assertEqual(lines[-200:], self.cli("logs").stdout.splitlines())

    def test_recent_flutter_and_dart_error_blocks(self):
        self.runtime.mkdir(parents=True)
        lines = ["Unhandled exception:", "old failure", "#0 oldFrame (old.dart:1)"]
        lines += [f"noise {index}" for index in range(405)]
        lines += [
            "══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞════",
            "A RenderFlex overflowed by 12 pixels.",
            "#0 Demo.build (package:fixture/main.dart:12:3)",
            "════════════════════",
            "Unhandled exception:",
            "Bad state: dart failure",
            f"VM source: {self.http_uri}",
            "#0 Parser.parse (package:fixture/parser.dart:5:7)",
        ]
        (self.runtime / "flutter.log").write_text("\n".join(lines) + "\n")
        errors = self.cli("errors").stdout
        for value in ("EXCEPTION CAUGHT", "RenderFlex", "#0 Demo.build",
                      "Unhandled exception", "Bad state", "#0 Parser.parse"):
            self.assertIn(value, errors)
        self.assertNotIn("old failure", errors)
        self.assertNotIn(SECRET, errors)

    def test_selected_summary_runs_the_complete_inspector_flow(self):
        self.start()
        self.wait_running()
        VMHandler.vm_isolates = [
            {"id": "isolates/system", "isSystemIsolate": True},
            {"id": "isolates/stale", "isSystemIsolate": False},
            {"id": "isolates/worker", "isSystemIsolate": False},
            {"id": "isolates/flutter+main", "isSystemIsolate": False},
        ]
        VMHandler.isolates = {
            "isolates/worker": {
                "type": "Isolate",
                "id": "isolates/worker",
                "extensionRPCs": ["ext.example.worker"],
            },
            "isolates/flutter+main": {
                "type": "Isolate",
                "id": "isolates/flutter+main",
                "extensionRPCs": [
                    "ext.flutter.inspector.show",
                    "ext.flutter.inspector.getSelectedSummaryWidget",
                ],
            },
        }
        VMHandler.summary = {
            "description": "DemoCard",
            "creationLocation": {
                "file": "file:///fixture/lib/main.dart",
                "line": 12,
                "column": 7,
                "name": "DemoCard.build",
                "extra": "discarded",
            },
            "createdByLocalProject": True,
            "children": ["discarded"],
        }
        VMHandler.paths = []
        VMHandler.requests = []

        result = self.cli("selected-summary")

        expected = {
            "description": "DemoCard",
            "creationLocation": {
                "file": "file:///fixture/lib/main.dart",
                "line": 12,
                "column": 7,
                "name": "DemoCard.build",
            },
            "createdByLocalProject": True,
        }
        self.assertEqual(expected, json.loads(result.stdout))
        self.assertNotIn(SECRET, result.stdout + result.stderr)
        self.assertEqual([
            "getVM",
            "getIsolate",
            "getIsolate",
            "getIsolate",
            "ext.flutter.inspector.show",
            "ext.flutter.inspector.getSelectedSummaryWidget",
        ], [request["method"] for request in VMHandler.requests])
        isolate_queries = [
            request["query"]["isolateId"]
            for request in VMHandler.requests
            if request["method"] == "getIsolate"
        ]
        self.assertEqual(
            ["isolates/stale", "isolates/worker", "isolates/flutter+main"],
            isolate_queries,
        )
        show_query = VMHandler.requests[-2]["query"]
        self.assertEqual(
            {"isolateId": "isolates/flutter+main", "enabled": "true"},
            show_query,
        )
        summary_query = VMHandler.requests[-1]["query"]
        self.assertEqual(
            {
                "isolateId": "isolates/flutter+main",
                "objectGroup": "flutter-mvvm-inspector",
            },
            summary_query,
        )
        VMHandler.summary_as_json = True
        self.assertEqual(expected, json.loads(self.cli("selected-summary").stdout))

    def test_selected_summary_reports_not_ready_and_no_selection_safely(self):
        not_ready = self.cli("selected-summary", check=False)
        self.assertEqual(1, not_ready.returncode)
        self.assertIn("VM Service is not ready", not_ready.stderr)

        self.start()
        self.wait_running()
        VMHandler.vm_isolates = [{"id": "isolates/flutter", "isSystemIsolate": False}]
        VMHandler.isolates = {
            "isolates/flutter": {
                "type": "Isolate",
                "id": "isolates/flutter",
                "extensionRPCs": [
                    "ext.flutter.inspector.show",
                    "ext.flutter.inspector.getSelectedSummaryWidget",
                ],
            },
        }
        VMHandler.summary = None
        VMHandler.paths = []
        VMHandler.requests = []

        no_selection = self.cli("selected-summary", check=False)

        self.assertEqual(1, no_selection.returncode)
        self.assertEqual("", no_selection.stdout)
        self.assertIn("no widget is selected", no_selection.stderr)
        self.assertNotIn(SECRET, no_selection.stderr)
        self.assertEqual(
            [
                "getVM",
                "getIsolate",
                "ext.flutter.inspector.show",
                "ext.flutter.inspector.getSelectedSummaryWidget",
            ],
            [request["method"] for request in VMHandler.requests],
        )

        (self.runtime / "vmservice.ws").write_text(
            f"ws://127.0.0.1:0/{SECRET}=/ws\n"
        )
        unreachable = self.cli("selected-summary", check=False)
        self.assertEqual(1, unreachable.returncode)
        self.assertEqual("", unreachable.stdout)
        self.assertIn("localhost network access", unreachable.stderr)
        self.assertNotIn(SECRET, unreachable.stderr)
        self.assertEqual("unreachable", self.status())

    def test_selected_summary_rejects_ambiguous_or_disabled_inspector(self):
        self.start()
        self.wait_running()
        extensions = [
            "ext.flutter.inspector.show",
            "ext.flutter.inspector.getSelectedSummaryWidget",
        ]
        VMHandler.vm_isolates = [
            {"id": "isolates/flutter-a", "isSystemIsolate": False},
            {"id": "isolates/flutter-b", "isSystemIsolate": False},
        ]
        VMHandler.isolates = {
            isolate_id: {
                "type": "Isolate",
                "id": isolate_id,
                "extensionRPCs": extensions,
            }
            for isolate_id in ("isolates/flutter-a", "isolates/flutter-b")
        }

        ambiguous = self.cli("selected-summary", check=False)

        self.assertEqual(1, ambiguous.returncode)
        self.assertEqual("", ambiguous.stdout)
        self.assertIn("multiple Flutter isolates", ambiguous.stderr)
        self.assertNotIn(SECRET, ambiguous.stderr)
        self.assertNotIn(
            "ext.flutter.inspector.show",
            [request["method"] for request in VMHandler.requests],
        )

        VMHandler.vm_isolates = [{"id": "isolates/flutter-a", "isSystemIsolate": False}]
        VMHandler.show_enabled = "false"
        VMHandler.requests = []
        disabled = self.cli("selected-summary", check=False)

        self.assertEqual(1, disabled.returncode)
        self.assertEqual("", disabled.stdout)
        self.assertIn("could not be enabled", disabled.stderr)
        self.assertEqual(
            ["getVM", "getIsolate", "ext.flutter.inspector.show"],
            [request["method"] for request in VMHandler.requests],
        )


if __name__ == "__main__":
    unittest.main()
