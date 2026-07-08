#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
from pathlib import Path


DEFAULT_INCLUDE_PATHS = (
    ".codex-plugin",
    "skills",
    "project-skills",
    "README.md",
)

EXCLUDED_FILE_NAMES = {
    ".DS_Store",
}

EXCLUDED_DIR_NAMES = {
    "__pycache__",
}

EXCLUDED_SUFFIXES = {
    ".pyc",
    ".pyo",
}


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def read_manifest(root: Path) -> dict:
    manifest_path = root / ".codex-plugin" / "plugin.json"
    with manifest_path.open(encoding="utf-8") as handle:
        return json.load(handle)


def should_include_file(path: Path) -> bool:
    if path.name in EXCLUDED_FILE_NAMES:
        return False
    if path.suffix in EXCLUDED_SUFFIXES:
        return False
    return not any(part in EXCLUDED_DIR_NAMES for part in path.parts)


def copy_plugin_source(root: Path, destination: Path) -> None:
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True)

    for relative in DEFAULT_INCLUDE_PATHS:
        source = root / relative
        if source.is_file():
            if should_include_file(source):
                target = destination / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
            continue

        if source.is_dir():
            for child in sorted(source.rglob("*")):
                if not child.is_file() or not should_include_file(child):
                    continue
                target = destination / child.relative_to(root)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(child, target)


def main() -> None:
    root = repo_root()
    manifest = read_manifest(root)
    plugin_name = manifest["name"]
    destination = root / "plugins" / plugin_name

    copy_plugin_source(root, destination)
    print(f"Synced marketplace plugin: {destination}")


if __name__ == "__main__":
    main()
