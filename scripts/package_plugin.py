#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import zipfile
from pathlib import Path


DEFAULT_INCLUDE_PATHS = (
    ".codex-plugin",
    "skills",
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


def iter_files(root: Path, include_examples: bool) -> list[Path]:
    include_paths = list(DEFAULT_INCLUDE_PATHS)
    if include_examples:
        include_paths.append("examples")

    files: list[Path] = []
    for relative in include_paths:
        path = root / relative
        if path.is_file():
            if should_include_file(path):
                files.append(path)
            continue
        if path.is_dir():
            files.extend(
                child
                for child in path.rglob("*")
                if child.is_file() and should_include_file(child)
            )
    return sorted(files)


def should_include_file(path: Path) -> bool:
    if path.name in EXCLUDED_FILE_NAMES:
        return False
    if path.suffix in EXCLUDED_SUFFIXES:
        return False
    return not any(part in EXCLUDED_DIR_NAMES for part in path.parts)


def build_archive(output_dir: Path, include_examples: bool) -> Path:
    root = repo_root()
    manifest = read_manifest(root)
    plugin_name = manifest["name"]
    version = manifest["version"]
    archive_path = output_dir / f"{plugin_name}-{version}.zip"

    if archive_path.exists():
        archive_path.unlink()

    with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in iter_files(root, include_examples):
            archive.write(path, path.relative_to(root).as_posix())

    return archive_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Package the Codex plugin as a zip archive.")
    parser.add_argument(
        "--output-dir",
        default="dist",
        help="Directory for generated plugin archives.",
    )
    parser.add_argument(
        "--include-examples",
        action="store_true",
        help="Include examples/ in the generated archive.",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Remove the output directory before packaging.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = repo_root()
    output_dir = (root / args.output_dir).resolve()

    if args.clean and output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    archive_path = build_archive(output_dir, args.include_examples)
    print(f"Created plugin archive: {archive_path}")


if __name__ == "__main__":
    main()
