#!/usr/bin/env python3
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import io
import json
import tarfile
from pathlib import Path


ASSET_NAME = "flutter-mvvm-skills.tar.gz"
DEFAULT_REPO = "foxman2/flutter_mvvm_skill"
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


def read_plugin_version(root: Path) -> str:
    manifest_path = root / ".codex-plugin" / "plugin.json"
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    base_version = str(data["version"]).split("+", 1)[0]
    return base_version if base_version.startswith("v") else f"v{base_version}"


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def should_include(path: Path) -> bool:
    if path.name in EXCLUDED_FILE_NAMES:
        return False
    if path.suffix in EXCLUDED_SUFFIXES:
        return False
    return not any(part in EXCLUDED_DIR_NAMES for part in path.parts)


def project_skill_dirs(root: Path) -> list[Path]:
    source_dir = root / "project-skills"
    if not source_dir.is_dir():
        raise FileNotFoundError(f"Project skills directory not found: {source_dir}")

    skills = sorted(path for path in source_dir.iterdir() if (path / "SKILL.md").is_file())
    if not skills:
        raise FileNotFoundError(f"No project skills found in: {source_dir}")
    return skills


def add_file(archive: tarfile.TarFile, source: Path, arcname: str) -> None:
    info = archive.gettarinfo(str(source), arcname)
    with source.open("rb") as handle:
        archive.addfile(info, handle)


def add_tree(archive: tarfile.TarFile, source: Path, arc_root: str) -> None:
    for path in sorted(source.rglob("*")):
        if not path.is_file() or not should_include(path):
            continue
        relative = path.relative_to(source)
        add_file(archive, path, f"{arc_root}/{relative.as_posix()}")


def add_manifest(
    archive: tarfile.TarFile,
    *,
    repo: str,
    version: str,
    managed_skills: list[str],
) -> None:
    manifest = {
        "source": f"github.com/{repo}",
        "repo": repo,
        "asset": ASSET_NAME,
        "version": version,
        "packagedAt": utc_timestamp(),
        "managedSkills": managed_skills,
    }
    content = json.dumps(manifest, indent=2, ensure_ascii=False).encode("utf-8") + b"\n"
    info = tarfile.TarInfo(".codex/flutter-mvvm-skills.json")
    info.size = len(content)
    info.mtime = int(datetime.now(timezone.utc).timestamp())
    archive.addfile(info, io.BytesIO(content))


def build_archive(output_dir: Path, version: str, repo: str) -> Path:
    root = repo_root()
    output_dir.mkdir(parents=True, exist_ok=True)
    archive_path = output_dir / ASSET_NAME
    if archive_path.exists():
        archive_path.unlink()

    skills = project_skill_dirs(root)
    managed_skills = [path.name for path in skills]
    updater = root / "scripts" / "update-codex-skills.sh"
    if not updater.is_file():
        raise FileNotFoundError(f"Updater script not found: {updater}")

    with tarfile.open(archive_path, "w:gz") as archive:
        for skill_dir in skills:
            add_tree(archive, skill_dir, f".codex/skills/{skill_dir.name}")
        add_file(archive, updater, "scripts/update-codex-skills.sh")
        add_manifest(
            archive,
            repo=repo,
            version=version,
            managed_skills=managed_skills,
        )

    return archive_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Package project-local Flutter MVVM Codex skills.")
    parser.add_argument(
        "--version",
        help="Release tag to record in the package, for example v0.1.3. Defaults to plugin version.",
    )
    parser.add_argument(
        "--repo",
        default=DEFAULT_REPO,
        help="GitHub repository recorded in the package manifest.",
    )
    parser.add_argument(
        "--output-dir",
        default="dist",
        help="Directory for the generated release asset.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = repo_root()
    version = args.version or read_plugin_version(root)
    archive_path = build_archive((root / args.output_dir).resolve(), version, args.repo)
    print(f"Created project skills release asset: {archive_path}")


if __name__ == "__main__":
    main()
