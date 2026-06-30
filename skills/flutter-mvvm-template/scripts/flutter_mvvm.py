#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


PROJECT_NAME_RE = re.compile(r"^[a-z][a-z0-9_]*$")
TEXT_SUFFIXES = {
    ".dart",
    ".yaml",
    ".yml",
    ".md",
    ".json",
    ".xml",
    ".gradle",
    ".kt",
    ".swift",
    ".plist",
}


class CliError(Exception):
    pass


def skill_root() -> Path:
    return Path(__file__).resolve().parents[1]


def run(cmd: list[str], cwd: Path | None = None, allow_failure: bool = False) -> int:
    print("+ " + " ".join(cmd))
    completed = subprocess.run(cmd, cwd=str(cwd) if cwd else None)
    if completed.returncode != 0 and not allow_failure:
        raise CliError(f"Command failed with exit code {completed.returncode}: {' '.join(cmd)}")
    return completed.returncode


def validate_project_name(name: str) -> None:
    if not PROJECT_NAME_RE.match(name):
        raise CliError(
            "Invalid Flutter project name. Use lowercase snake_case, starting with a letter."
        )


def validate_platforms(platforms: str) -> str:
    allowed = {"android", "ios", "web", "macos", "linux", "windows"}
    values = [item.strip() for item in platforms.split(",") if item.strip()]
    if not values:
        raise CliError("At least one platform is required.")
    unknown = sorted(set(values) - allowed)
    if unknown:
        raise CliError(f"Unknown platform(s): {', '.join(unknown)}")
    return ",".join(values)


def ensure_flutter() -> None:
    if shutil.which("flutter") is None:
        raise CliError("Flutter SDK was not found on PATH.")


def copy_overlay(overlay_dir: Path, target_dir: Path, replacements: dict[str, str]) -> None:
    for child_name in ("lib", "test"):
        path = target_dir / child_name
        if path.exists():
            shutil.rmtree(path)

    for item in overlay_dir.iterdir():
        if item.name == "template_pubspec_patch.yaml":
            continue
        destination = target_dir / item.name
        if item.is_dir():
            if destination.exists():
                shutil.rmtree(destination)
            shutil.copytree(item, destination)
        else:
            shutil.copy2(item, destination)

    replace_placeholders(target_dir, replacements)


def replace_placeholders(target_dir: Path, replacements: dict[str, str]) -> None:
    for path in target_dir.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in TEXT_SUFFIXES:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        original = text
        for key, value in replacements.items():
            text = text.replace(key, value)
        if text != original:
            path.write_text(text, encoding="utf-8")


def read_dependency_patch(patch_file: Path) -> dict[str, str]:
    dependencies: dict[str, str] = {}
    in_dependencies = False
    for raw_line in patch_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue
        if line == "dependencies:":
            in_dependencies = True
            continue
        if in_dependencies and not raw_line.startswith(" "):
            break
        if in_dependencies:
            stripped = line.strip()
            if ":" not in stripped:
                continue
            name, version = stripped.split(":", 1)
            dependencies[name.strip()] = version.strip()
    return dependencies


def merge_pubspec_dependencies(pubspec_file: Path, patch_file: Path) -> None:
    dependencies = read_dependency_patch(patch_file)
    text = pubspec_file.read_text(encoding="utf-8")
    lines = text.splitlines()
    existing = set()
    for line in lines:
        match = re.match(r"^\s{2}([a-zA-Z0-9_]+):", line)
        if match:
            existing.add(match.group(1))

    additions = [
        f"  {name}: {version}"
        for name, version in dependencies.items()
        if name not in existing
    ]
    if not additions:
        return

    for index, line in enumerate(lines):
        if line == "dependencies:":
            lines[index + 1:index + 1] = additions
            pubspec_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
            return
    raise CliError("Could not find dependencies: in pubspec.yaml")


def create_project(args: argparse.Namespace) -> None:
    validate_project_name(args.project_name)
    platforms = validate_platforms(args.platforms)
    ensure_flutter()

    output_dir = Path(args.output).expanduser().resolve()
    target_dir = output_dir / args.project_name
    if target_dir.exists() and any(target_dir.iterdir()) and not args.force:
        raise CliError(f"Target directory is not empty: {target_dir}. Use --force to overwrite template files.")

    output_dir.mkdir(parents=True, exist_ok=True)

    create_cmd = [
        "flutter",
        "create",
        args.project_name,
        "--org",
        args.org,
        "--platforms",
        platforms,
    ]
    if args.force:
        create_cmd.append("--overwrite")
    run(create_cmd, cwd=output_dir)

    overlay_dir = skill_root() / "assets" / "flutter_mvvm_overlay"
    replacements = {
        "{{project_name}}": args.project_name,
        "{{app_name}}": args.app_name or title_from_project_name(args.project_name),
        "{{org}}": args.org,
        "{{package_import}}": args.project_name,
    }
    copy_overlay(overlay_dir, target_dir, replacements)
    merge_pubspec_dependencies(
        target_dir / "pubspec.yaml",
        overlay_dir / "template_pubspec_patch.yaml",
    )

    pub_get_code = run(["flutter", "pub", "get"], cwd=target_dir, allow_failure=True)
    if pub_get_code != 0:
        print("flutter pub get failed. The project files were generated; run it manually after network/tooling is available.")
        return

    if not args.skip_final_checks:
        run(["dart", "format", "lib", "test"], cwd=target_dir, allow_failure=True)
        run(["flutter", "analyze"], cwd=target_dir, allow_failure=True)

    print(f"Created Flutter MVVM project at {target_dir}")


def title_from_project_name(name: str) -> str:
    return " ".join(part.capitalize() for part in name.split("_"))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="flutter-mvvm")
    subparsers = parser.add_subparsers(dest="command", required=True)

    create = subparsers.add_parser("create", help="Create a Flutter MVVM app from the bundled template.")
    create.add_argument("project_name")
    create.add_argument("--org", default="com.example")
    create.add_argument("--platforms", default="ios,android,web")
    create.add_argument("--output", default=".")
    create.add_argument("--app-name")
    create.add_argument("--force", action="store_true")
    create.add_argument("--skip-final-checks", action="store_true")
    create.set_defaults(func=create_project)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        args.func(args)
    except CliError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
