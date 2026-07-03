#!/usr/bin/env python3
from __future__ import annotations

import shutil
from pathlib import Path

from package_plugin import DEFAULT_INCLUDE_PATHS, read_manifest, repo_root, should_include_file


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
