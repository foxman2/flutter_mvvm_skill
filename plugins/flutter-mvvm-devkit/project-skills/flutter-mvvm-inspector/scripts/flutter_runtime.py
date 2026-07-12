#!/usr/bin/env python3
"""Keep one detached ``flutter run`` process for the current project."""

from __future__ import annotations

import argparse
import ipaddress
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import deque
from pathlib import Path
from typing import Any, Iterable


ROOT = Path.cwd()
RUN_DIR = ROOT / ".dart_tool" / "flutter-mvvm-inspector"
STATE = RUN_DIR / "state.json"
PID = RUN_DIR / "flutter.pid"
VM_WS = RUN_DIR / "vmservice.ws"
LOG = RUN_DIR / "flutter.log"
OLD_LOG = RUN_DIR / "flutter.log.1"

ANSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
VM_TOKEN_RE = re.compile(
    r"((?:https?|wss?)://(?:localhost|127(?:\.\d+){3}|0\.0\.0\.0|\[::1\])"
    r"(?::\d+)?/)(?!ws(?:[/\s?&#]|$))([A-Za-z0-9._~%+=-]+)", re.I
)
ENCODED_TOKEN_RE = re.compile(
    r"((?:https?|wss?)%3a%2f%2f(?:localhost|127(?:\.\d+){3}|0\.0\.0\.0|%5b::1%5d)"
    r"(?:%3a\d+)?%2f)(?!ws(?:%2f|$))(.+?)(?=%2f|%3f|%26|\s|$)", re.I
)
ERROR_RE = re.compile(
    r"exception caught by|unhandled exception|\b(?:Exception|Error|[A-Za-z_]\w*(?:Exception|Error)|"
    r"FlutterError|Assertion(?: failed)?)\s*:|bad state:|null check operator used on a null value|"
    r"is not a subtype of type|setState\(\) called after dispose|A RenderFlex overflowed", re.I
)
STACK_RE = re.compile(r"(?:^|:\s*)#\d+\s|<asynchronous suspension>|\.\.\.\s+normal element mounting")
MANAGED_FLAGS = {
    "--debug", "--profile", "--release", "--track-widget-creation",
    "--no-track-widget-creation", "--pid-file", "--vmservice-out-file",
    "--no-resident", "--disable-service-auth-codes",
}
INSPECTOR_SHOW = "ext.flutter.inspector.show"
INSPECTOR_SUMMARY = "ext.flutter.inspector.getSelectedSummaryWidget"
INSPECTOR_EXTENSIONS = {INSPECTOR_SHOW, INSPECTOR_SUMMARY}
INSPECTOR_OBJECT_GROUP = "flutter-mvvm-inspector"


class RuntimeCommandError(Exception):
    """A safe, user-facing helper failure."""


def ensure_run_dir() -> None:
    RUN_DIR.mkdir(parents=True, mode=0o700, exist_ok=True)
    os.chmod(RUN_DIR, 0o700)

def atomic_write(path: Path, text: str) -> None:
    ensure_run_dir()
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(text, encoding="utf-8")
    os.chmod(temporary, 0o600)
    os.replace(temporary, path)

def read_state() -> dict[str, Any]:
    try:
        value = json.loads(STATE.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}

def update_state(**changes: Any) -> None:
    state = read_state()
    state.update(changes)
    atomic_write(STATE, json.dumps(state, indent=2, sort_keys=True) + "\n")

def saved_pid() -> int | None:
    try:
        value = int(PID.read_text(encoding="ascii").strip())
    except (OSError, ValueError):
        value = read_state().get("pid", 0)
    return value if isinstance(value, int) and value > 1 else None

def pid_alive(pid: int | None) -> bool:
    if pid is None:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    try:  # kill(pid, 0) also succeeds for an unreaped Linux zombie.
        return Path(f"/proc/{pid}/stat").read_text().split()[2] != "Z"
    except OSError:
        return True

def ps_value(pid: int, field: str) -> str | None:
    try:
        result = subprocess.run(
            ["ps", "-ww", "-o", f"{field}=", "-p", str(pid)], capture_output=True,
            text=True, timeout=1, check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    value = result.stdout.strip()
    return value or None

def process_start_marker(pid: int) -> str | None:
    try:
        text = Path(f"/proc/{pid}/stat").read_text(encoding="ascii")
        return "proc:" + text[text.rfind(")") + 2:].split()[19]
    except (OSError, IndexError):
        value = ps_value(pid, "lstart")
        return "ps:" + value if value else None

def managed_pid() -> int | None:
    pid, state = saved_pid(), read_state()
    if not pid_alive(pid) or state.get("pid") != pid:
        return None
    try:
        return pid if os.getsid(pid) == pid else None
    except (AttributeError, OSError):
        return None

def verified_flutter_pid() -> int | None:
    pid, state = managed_pid(), read_state()
    if pid is None or state.get("process_start") != process_start_marker(pid):
        return None
    executable = state.get("flutter_executable")
    command = ps_value(pid, "command")
    if not isinstance(executable, str) or not command:
        return None
    is_flutter = executable in command or "flutter_tools.snapshot" in command
    has_owned_files = all(
        value in command for value in (f"--pid-file={PID}", f"--vmservice-out-file={VM_WS}")
    )
    return pid if is_flutter and has_owned_files else None

def is_loopback(host: str | None) -> bool:
    if not host:
        return False
    if host.lower() == "localhost":
        return True
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False

def http_base(ws_uri: str) -> str | None:
    try:
        parts = urllib.parse.urlsplit(ws_uri.strip())
        _ = parts.port  # Reject malformed ports now, before any request.
    except ValueError:
        return None
    scheme = {"ws": "http", "wss": "https"}.get(parts.scheme.lower())
    if (scheme is None or not parts.netloc or not is_loopback(parts.hostname)
            or parts.username is not None or parts.password is not None):
        return None
    path = parts.path.rstrip("/")
    if path == "/ws":
        path = "/"
    elif path.endswith("/ws"):
        path = path[:-2]
    else:
        return None
    if not path.endswith("/"):
        path += "/"
    return urllib.parse.urlunsplit((scheme, parts.netloc, path, parts.query, ""))


def vm_service_url(base: str, method: str, params: dict[str, str] | None = None) -> str:
    parts = urllib.parse.urlsplit(base)
    query = urllib.parse.parse_qsl(parts.query, keep_blank_values=True)
    if params:
        query.extend(params.items())
    return urllib.parse.urlunsplit(
        (parts.scheme, parts.netloc, parts.path + method, urllib.parse.urlencode(query), "")
    )


def vm_service_result(
    base: str,
    method: str,
    params: dict[str, str] | None = None,
) -> Any:
    request = urllib.request.Request(
        vm_service_url(base, method, params),
        headers={"Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=1.0) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeCommandError(f"{method} failed with HTTP {error.code}") from error
    except (OSError, ValueError, urllib.error.URLError) as error:
        raise RuntimeCommandError(f"{method} request failed") from error
    if not isinstance(payload, dict):
        raise RuntimeCommandError(f"{method} returned invalid JSON")
    if "error" in payload:
        error = payload["error"]
        message = error.get("message") if isinstance(error, dict) else None
        detail = message if isinstance(message, str) and message else "VM Service error"
        raise RuntimeCommandError(f"{method} failed: {detail}")
    if "result" not in payload:
        raise RuntimeCommandError(f"{method} response has no result")
    return payload["result"]


def validate_vm(base: str) -> bool:
    try:
        result = vm_service_result(base, "getVM")
    except RuntimeCommandError:
        return False
    return isinstance(result, dict) and (
        result.get("type") == "VM" or isinstance(result.get("isolates"), list)
    )


def managed_vm_base() -> str | None:
    if managed_pid() is None:
        return None
    try:
        return http_base(VM_WS.read_text(encoding="utf-8"))
    except OSError:
        return None


def live_vm() -> tuple[str, dict[str, Any]] | None:
    base = managed_vm_base()
    if base is None:
        return None
    try:
        result = vm_service_result(base, "getVM")
    except RuntimeCommandError:
        return None
    if not isinstance(result, dict) or not (
        result.get("type") == "VM" or isinstance(result.get("isolates"), list)
    ):
        return None
    update_state(status="running", vm_service_discovered_at=time.time())
    return base, result


def live_endpoint() -> str | None:
    live = live_vm()
    return live[0] if live else None

def status() -> str:
    if not STATE.exists() and not PID.exists():
        return "not_started"
    if managed_pid() is None:
        update_state(status="stopped")
        return "stopped"
    if live_endpoint():
        return "running"
    if managed_vm_base() is not None:
        update_state(status="unreachable")
        return "unreachable"
    update_state(status="starting")
    return "starting"

def start(flutter_args: list[str]) -> int:
    forbidden = [arg for arg in flutter_args if arg.split("=", 1)[0] in MANAGED_FLAGS]
    if flutter_args[:1] == ["run"] or forbidden:
        value = "flutter run" if flutter_args[:1] == ["run"] else forbidden[0]
        print(f"helper manages this Flutter option: {value}", file=sys.stderr)
        return 2
    if managed_pid() is not None:
        print(status())
        return 0

    flutter = shutil.which("flutter")
    if flutter is None:
        print("could not find flutter on PATH", file=sys.stderr)
        return 1
    os.umask(0o077)
    ensure_run_dir()
    if LOG.exists():
        os.replace(LOG, OLD_LOG)
    VM_WS.unlink(missing_ok=True)
    command = [
        flutter, "run", "--debug", "--track-widget-creation",
        f"--pid-file={PID}", f"--vmservice-out-file={VM_WS}", *flutter_args,
    ]
    try:
        with LOG.open("ab", buffering=0) as output:
            os.chmod(LOG, 0o600)
            process = subprocess.Popen(
                command, cwd=ROOT, stdin=subprocess.DEVNULL, stdout=output,
                stderr=subprocess.STDOUT, start_new_session=True, close_fds=True,
            )
    except OSError as error:
        print(f"could not start flutter: {error}", file=sys.stderr)
        return 1
    marker = process_start_marker(process.pid)
    if marker is None:
        process.terminate()
        print("could not verify the Flutter process identity", file=sys.stderr)
        return 1
    atomic_write(PID, f"{process.pid}\n")
    update_state(
        pid=process.pid, process_start=marker,
        flutter_executable=flutter,
        status="starting", started_at=time.time(),
    )
    print("starting")
    return 0

def tail_lines(limit: int) -> list[str]:
    lines: deque[str] = deque(maxlen=max(0, limit))
    for path in (OLD_LOG, LOG):
        try:
            with path.open(encoding="utf-8", errors="replace") as stream:
                lines.extend(line.rstrip("\r\n") for line in stream)
        except OSError:
            pass
    return list(lines)

def redact(text: str) -> str:
    text = VM_TOKEN_RE.sub(r"\1<redacted>", text)
    return ENCODED_TOKEN_RE.sub(r"\1%3Credacted%3E", text)

def error_blocks(lines: Iterable[str]) -> list[str]:
    source, blocks, index = list(lines), [], 0
    while index < len(source):
        if not ERROR_RE.search(ANSI_RE.sub("", source[index])):
            index += 1
            continue
        block, saw_stack, prelude = [source[index]], False, 0
        index += 1
        while index < len(source) and len(block) < 80:
            plain = ANSI_RE.sub("", source[index])
            if ERROR_RE.search(plain):
                break
            if STACK_RE.search(plain):
                saw_stack = True
            elif saw_stack and plain.strip() and "══" not in plain:
                break
            elif not saw_stack:
                prelude += 1
                if prelude > 30:
                    break
            block.append(source[index])
            index += 1
        blocks.append("\n".join(block).rstrip())
    return [block for block in blocks if block]


def inspector_isolate(base: str, vm: dict[str, Any]) -> str:
    isolate_refs = vm.get("isolates")
    if not isinstance(isolate_refs, list):
        raise RuntimeCommandError("getVM returned no isolate list")
    matches: list[str] = []
    for isolate_ref in isolate_refs:
        if not isinstance(isolate_ref, dict) or isolate_ref.get("isSystemIsolate") is True:
            continue
        isolate_id = isolate_ref.get("id")
        if not isinstance(isolate_id, str) or not isolate_id:
            continue
        try:
            isolate = vm_service_result(base, "getIsolate", {"isolateId": isolate_id})
        except RuntimeCommandError:
            continue
        if not isinstance(isolate, dict) or isolate.get("isSystemIsolate") is True:
            continue
        extensions = isolate.get("extensionRPCs")
        if isinstance(extensions, list) and INSPECTOR_EXTENSIONS.issubset(
            value for value in extensions if isinstance(value, str)
        ):
            matches.append(isolate_id)
    if not matches:
        raise RuntimeCommandError(
            "no Flutter isolate with the required Inspector extensions is ready"
        )
    if len(matches) > 1:
        raise RuntimeCommandError(
            "multiple Flutter isolates expose the required Inspector extensions"
        )
    return matches[0]


def inspector_summary_value(response: Any) -> Any:
    if not isinstance(response, dict) or "result" not in response:
        raise RuntimeCommandError("selected widget summary response has an invalid format")
    value = response["result"]
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except ValueError as error:
            raise RuntimeCommandError(
                "selected widget summary response has invalid JSON"
            ) from error
    return value


def selected_summary() -> dict[str, Any]:
    base = managed_vm_base()
    if base is None:
        raise RuntimeCommandError("Flutter VM Service is not ready")
    try:
        vm = vm_service_result(base, "getVM")
    except RuntimeCommandError as error:
        raise RuntimeCommandError(
            "Flutter VM Service endpoint exists but is unreachable; "
            "rerun selected-summary with localhost network access"
        ) from error
    if not isinstance(vm, dict) or not (
        vm.get("type") == "VM" or isinstance(vm.get("isolates"), list)
    ):
        raise RuntimeCommandError("getVM returned an invalid VM response")
    update_state(status="running", vm_service_discovered_at=time.time())
    isolate_id = inspector_isolate(base, vm)
    show = vm_service_result(
        base,
        INSPECTOR_SHOW,
        {"isolateId": isolate_id, "enabled": "true"},
    )
    enabled = show.get("enabled") if isinstance(show, dict) else None
    if enabled not in (True, "true"):
        raise RuntimeCommandError("Flutter Inspector selection mode could not be enabled")
    summary = inspector_summary_value(
        vm_service_result(
            base,
            INSPECTOR_SUMMARY,
            {"isolateId": isolate_id, "objectGroup": INSPECTOR_OBJECT_GROUP},
        )
    )
    if summary is None:
        raise RuntimeCommandError("no widget is selected; select one in the app and run again")
    if not isinstance(summary, dict):
        raise RuntimeCommandError("selected widget summary has an invalid format")
    location = summary.get("creationLocation")
    if not isinstance(location, dict):
        location = {}
    return {
        "description": summary.get("description"),
        "creationLocation": {
            "file": location.get("file"),
            "line": location.get("line"),
            "column": location.get("column"),
            "name": location.get("name"),
        },
        "createdByLocalProject": summary.get("createdByLocalProject"),
    }

def signal_process(pid: int, sig: signal.Signals) -> None:
    try:
        if hasattr(os, "getpgid") and os.getpgid(pid) == pid:
            os.killpg(pid, sig)
        else:
            os.kill(pid, sig)
    except (ProcessLookupError, PermissionError):
        pass

def stop() -> int:
    pid = verified_flutter_pid()
    if pid is not None and pid != os.getpid():
        signal_process(pid, signal.SIGTERM)
        deadline = time.monotonic() + 3.0
        while pid_alive(pid) and time.monotonic() < deadline:
            time.sleep(0.05)
        if pid_alive(pid):
            signal_process(pid, signal.SIGKILL)
        atomic_write(PID, f"{pid}\n")
    if STATE.exists() or PID.exists():
        update_state(status="stopped", stopped_at=time.time())
    print("stopped")
    return 0

def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)
    start_parser = commands.add_parser("start")
    start_parser.add_argument("flutter_args", nargs=argparse.REMAINDER)
    commands.add_parser("status")
    for name, default in (("logs", 200), ("errors", 400)):
        command = commands.add_parser(name)
        command.add_argument("--lines", type=int, default=default)
    commands.add_parser("endpoint")
    commands.add_parser("selected-summary")
    commands.add_parser("stop")
    return result

def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    if args.command == "start":
        values = args.flutter_args[1:] if args.flutter_args[:1] == ["--"] else args.flutter_args
        return start(values)
    if args.command == "status":
        print(status())
    elif args.command in {"logs", "errors"}:
        if args.lines < 0:
            parser().error("--lines must be non-negative")
        lines = tail_lines(args.lines)
        text = "\n".join(lines if args.command == "logs" else error_blocks(lines))
        if text:
            print(redact(text))
    elif args.command == "endpoint":
        endpoint = live_endpoint()
        if endpoint is None:
            print("Flutter VM Service is not ready", file=sys.stderr)
            return 1
        print(endpoint)
    elif args.command == "selected-summary":
        try:
            summary = selected_summary()
        except RuntimeCommandError as error:
            print(redact(str(error)), file=sys.stderr)
            return 1
        print(json.dumps(summary, ensure_ascii=False, indent=2))
    elif args.command == "stop":
        return stop()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
