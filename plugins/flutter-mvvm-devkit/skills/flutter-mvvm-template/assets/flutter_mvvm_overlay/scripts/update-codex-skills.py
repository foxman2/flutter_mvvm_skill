#!/usr/bin/env python3
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import stat
import sys
import tarfile
import tempfile
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


DEFAULT_REPO = "foxman2/flutter_mvvm_skill"
ASSET_NAME = "flutter-mvvm-skills.tar.gz"
GITHUB_API_VERSION = "2022-11-28"
USER_AGENT = "flutter-mvvm-skills-updater"


class UpdateError(Exception):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Update project-local Flutter MVVM Codex skills.")
    parser.add_argument(
        "--version",
        help="Install a specific GitHub Release tag, for example v0.1.3.",
    )
    parser.add_argument(
        "--archive",
        help="Install from a local flutter-mvvm-skills.tar.gz archive.",
    )
    parser.add_argument(
        "--repo",
        default=DEFAULT_REPO,
        help=f"Override the GitHub repository. Defaults to {DEFAULT_REPO}.",
    )
    args = parser.parse_args()
    if args.version and args.archive:
        parser.error("use either --version or --archive, not both")
    return args


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def project_root() -> Path:
    return Path(__file__).resolve().parents[1]


def github_headers(token: str | None = None, *, accept: str) -> dict[str, str]:
    headers = {
        "Accept": accept,
        "User-Agent": USER_AGENT,
        "X-GitHub-Api-Version": GITHUB_API_VERSION,
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def http_error_message(error: HTTPError) -> str:
    try:
        body = error.read().decode("utf-8", errors="replace").strip()
    except OSError:
        body = ""
    if body:
        return f"{error.code} {error.reason}: {body}"
    return f"{error.code} {error.reason}"


def download_url(url: str, destination: Path, headers: dict[str, str] | None = None) -> None:
    request_headers = {"User-Agent": USER_AGENT}
    if headers:
        request_headers.update(headers)
    request = Request(url, headers=request_headers)
    try:
        with urlopen(request) as response, destination.open("wb") as output:
            shutil.copyfileobj(response, output)
    except HTTPError as error:
        raise UpdateError(f"download failed: {url} ({http_error_message(error)})") from error
    except URLError as error:
        raise UpdateError(f"download failed: {url} ({error.reason})") from error
    except OSError as error:
        raise UpdateError(f"download failed: {url} ({error})") from error


def download_public_asset(repo: str, version: str | None, destination: Path) -> None:
    if version:
        url = f"https://github.com/{repo}/releases/download/{version}/{ASSET_NAME}"
    else:
        url = f"https://github.com/{repo}/releases/latest/download/{ASSET_NAME}"
    download_url(url, destination)


def read_github_json(url: str, token: str) -> dict:
    request = Request(
        url,
        headers=github_headers(token, accept="application/vnd.github+json"),
    )
    try:
        with urlopen(request) as response:
            return json.load(response)
    except HTTPError as error:
        raise UpdateError(f"GitHub API request failed: {url} ({http_error_message(error)})") from error
    except URLError as error:
        raise UpdateError(f"GitHub API request failed: {url} ({error.reason})") from error
    except json.JSONDecodeError as error:
        raise UpdateError(f"GitHub API returned invalid JSON: {url}") from error


def download_api_asset(repo: str, version: str | None, token: str, destination: Path) -> None:
    if version:
        release_url = f"https://api.github.com/repos/{repo}/releases/tags/{version}"
    else:
        release_url = f"https://api.github.com/repos/{repo}/releases/latest"

    release = read_github_json(release_url, token)
    asset_id = None
    for asset in release.get("assets", []):
        if asset.get("name") == ASSET_NAME:
            asset_id = asset.get("id")
            break

    if asset_id is None:
        raise UpdateError(f"release asset not found: {ASSET_NAME}")

    asset_url = f"https://api.github.com/repos/{repo}/releases/assets/{asset_id}"
    download_url(
        asset_url,
        destination,
        github_headers(token, accept="application/octet-stream"),
    )


def download_asset(repo: str, version: str | None, destination: Path) -> None:
    try:
        download_public_asset(repo, version, destination)
        return
    except UpdateError as public_error:
        token = os.environ.get("GITHUB_TOKEN")
        if not token:
            raise UpdateError(
                f"could not download {ASSET_NAME}; set GITHUB_TOKEN for private releases "
                f"({public_error})"
            ) from public_error

    print("Public release download failed; retrying through the GitHub API with GITHUB_TOKEN.", file=sys.stderr)
    download_api_asset(repo, version, token, destination)


def safe_member_name(name: str) -> bool:
    path = PurePosixPath(name)
    if path.is_absolute() or not name:
        return False
    return all(part not in {"", ".", ".."} for part in path.parts)


def extract_archive(archive_path: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    try:
        with tarfile.open(archive_path, "r:gz") as archive:
            for member in archive.getmembers():
                if not safe_member_name(member.name):
                    raise UpdateError(f"archive contains unsafe path: {member.name}")
                if member.issym() or member.islnk():
                    raise UpdateError(f"archive contains unsupported link: {member.name}")
                if not (member.isdir() or member.isfile()):
                    raise UpdateError(f"archive contains unsupported member: {member.name}")
            archive.extractall(destination)
    except tarfile.TarError as error:
        raise UpdateError(f"could not extract archive: {archive_path}") from error


def read_json_file(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise UpdateError(f"invalid JSON file: {path}") from error
    except OSError as error:
        raise UpdateError(f"could not read file: {path}") from error


def validate_skill_name(name: object) -> str:
    if not isinstance(name, str) or not name.strip():
        raise UpdateError(f"invalid managed skill name: {name!r}")
    normalized = name.strip()
    if normalized in {".", ".."} or "/" in normalized or "\\" in normalized:
        raise UpdateError(f"unsafe managed skill name: {normalized}")
    return normalized


def normalize_skill_names(names: list[object]) -> list[str]:
    normalized_names = []
    seen = set()
    for name in names:
        normalized = validate_skill_name(name)
        if normalized in seen:
            continue
        seen.add(normalized)
        normalized_names.append(normalized)
    return normalized_names


def manifest_skill_names(manifest_path: Path) -> list[str]:
    data = read_json_file(manifest_path)
    names = data.get("managedSkills") or []
    if not isinstance(names, list):
        raise UpdateError(f"managedSkills must be a list in {manifest_path}")
    return normalize_skill_names(names)


def incoming_skill_names(manifest_path: Path, skills_dir: Path) -> list[str]:
    names = manifest_skill_names(manifest_path)
    if not names:
        names = normalize_skill_names(
            sorted(path.name for path in skills_dir.iterdir() if (path / "SKILL.md").is_file())
        )
    if not names:
        raise UpdateError("archive does not declare any managed skills")
    return names


def current_skill_names(manifest_path: Path, fallback_names: list[str]) -> list[str]:
    names = manifest_skill_names(manifest_path)
    return names or fallback_names


def remove_path(path: Path) -> None:
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    elif path.exists() or path.is_symlink():
        path.unlink()


def copy_updater(extract_dir: Path, root: Path) -> None:
    source = extract_dir / "scripts" / "update-codex-skills.py"
    scripts_dir = root / "scripts"
    scripts_dir.mkdir(parents=True, exist_ok=True)

    if source.is_file():
        destination = scripts_dir / "update-codex-skills.py"
        shutil.copy2(source, destination)
        destination.chmod(destination.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    legacy_shell = scripts_dir / "update-codex-skills.sh"
    if legacy_shell.exists() or legacy_shell.is_symlink():
        legacy_shell.unlink()


def write_project_manifest(
    incoming_manifest: Path,
    target_manifest: Path,
    *,
    repo: str,
    version: str | None,
    managed_skills: list[str],
) -> None:
    data = read_json_file(incoming_manifest)
    data["source"] = f"github.com/{repo}"
    data["repo"] = repo
    data["asset"] = ASSET_NAME
    if version:
        data["version"] = version
    data["installedAt"] = utc_timestamp()
    data["managedSkills"] = sorted(normalize_skill_names(data.get("managedSkills") or managed_skills))

    target_manifest.parent.mkdir(parents=True, exist_ok=True)
    target_manifest.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def install_skills(root: Path, extract_dir: Path, repo: str, version: str | None) -> str:
    incoming_manifest = extract_dir / ".codex" / "flutter-mvvm-skills.json"
    incoming_skills_dir = extract_dir / ".codex" / "skills"
    if not incoming_skills_dir.is_dir():
        raise UpdateError("archive does not contain .codex/skills")

    incoming_names = incoming_skill_names(incoming_manifest, incoming_skills_dir)
    current_manifest = root / ".codex" / "flutter-mvvm-skills.json"
    current_names = current_skill_names(current_manifest, incoming_names)

    skills_root = root / ".codex" / "skills"
    skills_root.mkdir(parents=True, exist_ok=True)

    for skill_name in current_names:
        remove_path(skills_root / skill_name)

    for skill_name in incoming_names:
        source_dir = incoming_skills_dir / skill_name
        if not source_dir.is_dir():
            raise UpdateError(f"managed skill missing from archive: {skill_name}")
        destination = skills_root / skill_name
        remove_path(destination)
        shutil.copytree(source_dir, destination)

    copy_updater(extract_dir, root)
    write_project_manifest(
        incoming_manifest,
        current_manifest,
        repo=repo,
        version=version,
        managed_skills=incoming_names,
    )
    return str(read_json_file(current_manifest).get("version", "unknown"))


def archive_path_from_args(args: argparse.Namespace, tmp_dir: Path) -> Path:
    if args.archive:
        archive_path = Path(args.archive).expanduser().resolve()
        if not archive_path.is_file():
            raise UpdateError(f"archive not found: {archive_path}")
        return archive_path

    archive_path = tmp_dir / ASSET_NAME
    download_asset(args.repo, args.version, archive_path)
    return archive_path


def run() -> int:
    args = parse_args()
    root = project_root()
    try:
        with tempfile.TemporaryDirectory(prefix="flutter-mvvm-skills-") as tmp:
            tmp_dir = Path(tmp)
            archive_path = archive_path_from_args(args, tmp_dir)
            extract_dir = tmp_dir / "extract"
            extract_archive(archive_path, extract_dir)
            installed_version = install_skills(root, extract_dir, args.repo, args.version)
    except UpdateError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"Updated Flutter MVVM Codex skills to {installed_version}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
