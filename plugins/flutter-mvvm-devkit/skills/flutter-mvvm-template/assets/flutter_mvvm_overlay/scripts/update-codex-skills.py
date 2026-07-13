#!/usr/bin/env python3
"""通过 Git sparse checkout 更新项目本地的 Flutter MVVM Codex skills。"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile


REPO = "foxman2/flutter_mvvm_skill"
REPO_URL = f"https://github.com/{REPO}.git"
DEFAULT_REF = "main"
VERSION_TAG_RE = re.compile(
    r"^v(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)"
    r"(?:-(?:0|[1-9]\d*|[A-Za-z-][0-9A-Za-z-]*)"
    r"(?:\.(?:0|[1-9]\d*|[A-Za-z-][0-9A-Za-z-]*))*)?$"
)
SKILL_FRONTMATTER_RE = re.compile(r"\A---\r?\n(?P<header>.*?)\r?\n---(?:\r?\n|\Z)", re.DOTALL)

MANIFEST_PATH = Path(".codex") / "flutter-mvvm-skills.json"
TARGET_SKILLS_PATH = Path(".codex") / "skills"
TARGET_UPDATER_PATH = Path("scripts") / "update-codex-skills.py"
LEGACY_UPDATER_PATH = Path("scripts") / "update-codex-skills.sh"

SOURCE_SKILLS_PATH = Path("project-skills")
SOURCE_PLUGIN_MANIFEST_PATH = Path(".codex-plugin") / "plugin.json"
SOURCE_UPDATER_DIR = (
    Path("skills")
    / "flutter-mvvm-template"
    / "assets"
    / "flutter_mvvm_overlay"
    / "scripts"
)
SOURCE_UPDATER_PATH = SOURCE_UPDATER_DIR / "update-codex-skills.py"
SPARSE_PATHS = (
    SOURCE_SKILLS_PATH.as_posix(),
    SOURCE_PLUGIN_MANIFEST_PATH.parent.as_posix(),
    SOURCE_UPDATER_DIR.as_posix(),
)
SPARSE_PATTERNS = tuple(f"/{path}/" for path in SPARSE_PATHS)


class UpdateError(Exception):
    """更新过程中的可预期错误。"""


@dataclass(frozen=True)
class SourcePackage:
    root: Path
    version: str
    skill_names: tuple[str, ...]


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Update project-local Flutter MVVM Codex skills.")
    parser.add_argument(
        "--version",
        help="Checkout a specific repository tag, for example v0.1.7. Defaults to main.",
    )
    return parser.parse_args(argv)


def project_root() -> Path:
    # 安装后脚本位于 <project>/scripts/update-codex-skills.py。
    return Path(__file__).resolve().parents[1]


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def validate_requested_ref(version: str | None) -> str:
    if version is None:
        return DEFAULT_REF
    if not VERSION_TAG_RE.fullmatch(version):
        raise UpdateError(
            f"invalid version tag: {version!r}; expected vX.Y.Z or a SemVer prerelease tag"
        )
    return version


def git_executable() -> str:
    executable = shutil.which("git")
    if executable is None:
        raise UpdateError("git is required but was not found on PATH")
    return executable


def command_error(completed: subprocess.CompletedProcess[str]) -> str:
    detail = (completed.stderr or completed.stdout).strip()
    return detail or f"exit code {completed.returncode}"


def clone_source(destination: Path, ref: str, repo_url: str = REPO_URL) -> None:
    """浅克隆指定 ref，并只检出安装所需的三个源码目录。"""
    git = git_executable()
    clone_command = [
        git,
        "clone",
        "--depth",
        "1",
        "--filter=blob:none",
        "--sparse",
        "--single-branch",
        "--branch",
        ref,
        repo_url,
        str(destination),
    ]
    completed = subprocess.run(clone_command, capture_output=True, text=True)
    if completed.returncode != 0:
        raise UpdateError(f"git clone failed for ref {ref!r}: {command_error(completed)}")

    sparse_command = [
        git,
        "-C",
        str(destination),
        "sparse-checkout",
        "set",
        "--no-cone",
        *SPARSE_PATTERNS,
    ]
    completed = subprocess.run(sparse_command, capture_output=True, text=True)
    if completed.returncode != 0:
        raise UpdateError(f"git sparse checkout failed: {command_error(completed)}")


def read_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise UpdateError(f"invalid JSON file: {path}") from error
    except OSError as error:
        raise UpdateError(f"could not read file: {path} ({error})") from error
    if not isinstance(data, dict):
        raise UpdateError(f"JSON root must be an object: {path}")
    return data


def normalize_skill_names(names: list[object]) -> list[str]:
    """校验 skill 名称、去重，并保留输入顺序。"""
    result: list[str] = []
    seen: set[str] = set()
    for raw_name in names:
        if not isinstance(raw_name, str) or not raw_name.strip():
            raise UpdateError(f"invalid managed skill name: {raw_name!r}")
        name = raw_name.strip()
        if name in {".", ".."} or "/" in name or "\\" in name:
            raise UpdateError(f"unsafe managed skill name: {name}")
        if name not in seen:
            seen.add(name)
            result.append(name)
    return result


def manifest_skill_names(manifest_path: Path) -> list[str]:
    names = read_json(manifest_path).get("managedSkills") or []
    if not isinstance(names, list):
        raise UpdateError(f"managedSkills must be a list in {manifest_path}")
    return normalize_skill_names(names)


def require_regular_file(path: Path, label: str) -> None:
    if path.is_symlink() or not path.is_file():
        raise UpdateError(f"invalid source structure: {label} is missing or is not a regular file: {path}")


def validate_skill(skill_dir: Path) -> None:
    if skill_dir.is_symlink() or not skill_dir.is_dir():
        raise UpdateError(f"invalid source structure: invalid skill directory: {skill_dir}")
    for child in skill_dir.rglob("*"):
        if child.is_symlink():
            raise UpdateError(f"invalid source structure: skill contains a symlink: {child}")

    skill_file = skill_dir / "SKILL.md"
    require_regular_file(skill_file, f"{skill_dir.name}/SKILL.md")
    try:
        text = skill_file.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise UpdateError(f"invalid source structure: could not read {skill_file} ({error})") from error
    match = SKILL_FRONTMATTER_RE.match(text)
    if match is None:
        raise UpdateError(f"invalid source structure: invalid SKILL.md frontmatter: {skill_file}")

    header = match.group("header")
    name_match = re.search(r"(?m)^name:\s*([^\s#]+)\s*$", header)
    description_match = re.search(r"(?m)^description:\s*\S.*$", header)
    if name_match is None or name_match.group(1) != skill_dir.name or description_match is None:
        raise UpdateError(f"invalid source structure: invalid SKILL.md metadata: {skill_file}")


def inspect_source(root: Path) -> SourcePackage:
    """在任何目标项目写入前完整验证检出的源码。"""
    skills_dir = root / SOURCE_SKILLS_PATH
    if skills_dir.is_symlink() or not skills_dir.is_dir():
        raise UpdateError(f"invalid source structure: missing directory: {SOURCE_SKILLS_PATH}")

    skill_names: list[str] = []
    try:
        entries = sorted(skills_dir.iterdir(), key=lambda path: path.name)
    except OSError as error:
        raise UpdateError(f"invalid source structure: could not read {skills_dir} ({error})") from error
    for entry in entries:
        if not entry.is_dir() or entry.is_symlink():
            raise UpdateError(f"invalid source structure: unexpected entry in project-skills: {entry.name}")
        validate_skill(entry)
        skill_names.append(entry.name)
    if not skill_names:
        raise UpdateError("invalid source structure: project-skills does not contain any skills")

    plugin_manifest = root / SOURCE_PLUGIN_MANIFEST_PATH
    require_regular_file(plugin_manifest, SOURCE_PLUGIN_MANIFEST_PATH.as_posix())
    try:
        plugin_data = read_json(plugin_manifest)
    except UpdateError as error:
        raise UpdateError(f"invalid source structure: {error}") from error
    version = plugin_data.get("version")
    if not isinstance(version, str) or not version.strip():
        raise UpdateError(
            f"invalid source structure: version is missing from {SOURCE_PLUGIN_MANIFEST_PATH}"
        )

    updater = root / SOURCE_UPDATER_PATH
    require_regular_file(updater, SOURCE_UPDATER_PATH.as_posix())
    return SourcePackage(root=root, version=version.strip(), skill_names=tuple(skill_names))


def remove_path(path: Path) -> None:
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    elif path.exists() or path.is_symlink():
        path.unlink()


def install_updater(package: SourcePackage, root: Path) -> None:
    source = package.root / SOURCE_UPDATER_PATH
    destination = root / TARGET_UPDATER_PATH
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    destination.chmod(destination.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    remove_path(root / LEGACY_UPDATER_PATH)


def manifest_data(package: SourcePackage, ref: str) -> dict:
    return {
        "source": f"github.com/{REPO}",
        "repo": REPO,
        "ref": ref,
        "version": package.version,
        "installedAt": utc_timestamp(),
        "managedSkills": list(package.skill_names),
    }


def write_manifest(target: Path, package: SourcePackage, ref: str) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        json.dumps(manifest_data(package, ref), indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def install_source(root: Path, package: SourcePackage, ref: str) -> None:
    """替换旧 manifest 管理的 skills，并保留其余项目本地 skills。"""
    target_manifest = root / MANIFEST_PATH
    old_names = manifest_skill_names(target_manifest)
    target_skills = root / TARGET_SKILLS_PATH
    source_skills = package.root / SOURCE_SKILLS_PATH

    target_skills.mkdir(parents=True, exist_ok=True)
    for name in old_names:
        remove_path(target_skills / name)
    for name in package.skill_names:
        destination = target_skills / name
        remove_path(destination)
        shutil.copytree(source_skills / name, destination)

    install_updater(package, root)
    # 最后写 manifest，避免前面的复制失败却记录为已完成。
    write_manifest(target_manifest, package, ref)


def update_project(root: Path, ref: str, repo_url: str = REPO_URL) -> SourcePackage:
    """先在临时目录 clone 和验证，再开始修改目标项目。"""
    with tempfile.TemporaryDirectory(prefix="flutter-mvvm-skills-") as tmp:
        checkout = Path(tmp) / "source"
        clone_source(checkout, ref, repo_url)
        package = inspect_source(checkout)
        install_source(root, package, ref)
        return package


def run(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        ref = validate_requested_ref(args.version)
        package = update_project(project_root(), ref)
    except (UpdateError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(
        f"Updated Flutter MVVM Codex skills from {ref} "
        f"(source version {package.version})."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
