#!/usr/bin/env python3
"""从 GitHub Release 更新项目本地的 Flutter MVVM Codex skills。

流程很短：
1. 下载固定仓库里的 flutter-mvvm-skills.tar.gz。
2. 在临时目录中安全解压。
3. 只替换 manifest 声明的 managedSkills。
4. 写回 manifest，并同步下一版 updater。
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
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
USER_AGENT = "flutter-mvvm-skills-updater"

# 发布包内和目标项目内使用同一组相对路径。
MANIFEST_PATH = Path(".codex") / "flutter-mvvm-skills.json"
SKILLS_PATH = Path(".codex") / "skills"
UPDATER_PATH = Path("scripts") / "update-codex-skills.py"
LEGACY_UPDATER_PATH = Path("scripts") / "update-codex-skills.sh"


class UpdateError(Exception):
    """更新过程中的可预期错误。"""


def parse_args() -> argparse.Namespace:
    """只保留 --version；仓库和 asset 名称固定在脚本常量里。"""
    parser = argparse.ArgumentParser(description="Update project-local Flutter MVVM Codex skills.")
    parser.add_argument("--version", help="Install a specific GitHub Release tag, for example v0.1.3.")
    return parser.parse_args()


def project_root() -> Path:
    # 安装后脚本位于 <project>/scripts/update-codex-skills.py。
    return Path(__file__).resolve().parents[1]


def utc_timestamp() -> str:
    """生成 manifest 里记录安装时间用的 UTC 时间戳。"""
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def release_url(version: str | None) -> str:
    """version 为空时下载 latest，否则下载指定 tag 的 release asset。"""
    release_path = f"download/{version}" if version else "latest/download"
    return f"https://github.com/{DEFAULT_REPO}/releases/{release_path}/{ASSET_NAME}"


def http_error_message(error: HTTPError) -> str:
    """把 HTTP 状态和响应体合并成更有用的错误信息。"""
    try:
        body = error.read().decode("utf-8", errors="replace").strip()
    except OSError:
        body = ""
    return f"{error.code} {error.reason}: {body}" if body else f"{error.code} {error.reason}"


def download_archive(version: str | None, destination: Path) -> None:
    """下载 release asset 到临时目录中的目标文件。"""
    url = release_url(version)
    request = Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urlopen(request) as response, destination.open("wb") as output:
            shutil.copyfileobj(response, output)
    except HTTPError as error:
        raise UpdateError(f"download failed: {url} ({http_error_message(error)})") from error
    except URLError as error:
        raise UpdateError(f"download failed: {url} ({error.reason})") from error
    except OSError as error:
        raise UpdateError(f"download failed: {url} ({error})") from error


def validate_archive_member(member: tarfile.TarInfo) -> None:
    """校验 tar 成员，防止恶意压缩包写出目标目录。"""
    # 禁止 ../、绝对路径、空路径和链接；只接受普通文件和目录。
    path = PurePosixPath(member.name)
    unsafe_name = path.is_absolute() or not member.name or any(
        part in {"", ".", ".."} for part in path.parts
    )
    if unsafe_name:
        raise UpdateError(f"archive contains unsafe path: {member.name}")
    if member.issym() or member.islnk():
        raise UpdateError(f"archive contains unsupported link: {member.name}")
    if not (member.isdir() or member.isfile()):
        raise UpdateError(f"archive contains unsupported member: {member.name}")


def extract_archive(archive_path: Path, destination: Path) -> None:
    """先检查所有 tar 成员，再整体解压。"""
    destination.mkdir(parents=True, exist_ok=True)
    try:
        with tarfile.open(archive_path, "r:gz") as archive:
            for member in archive.getmembers():
                validate_archive_member(member)
            archive.extractall(destination)
    except tarfile.TarError as error:
        raise UpdateError(f"could not extract archive: {archive_path}") from error


def read_json(path: Path) -> dict:
    """读取 JSON；文件不存在时返回空 dict，兼容首次安装和旧包。"""
    if not path.is_file():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise UpdateError(f"invalid JSON file: {path}") from error
    except OSError as error:
        raise UpdateError(f"could not read file: {path}") from error


def normalize_skill_names(names: list[object]) -> list[str]:
    """校验 skill 名称、去重，并保留 manifest 中的原始顺序。"""
    result: list[str] = []
    seen = set()
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
    """读取 manifest 的 managedSkills 字段。"""
    names = read_json(manifest_path).get("managedSkills") or []
    if not isinstance(names, list):
        raise UpdateError(f"managedSkills must be a list in {manifest_path}")
    return normalize_skill_names(names)


def incoming_skill_names(manifest_path: Path, skills_dir: Path) -> list[str]:
    # 旧发布包可能没有 managedSkills，这时退回到扫描含 SKILL.md 的目录。
    names = manifest_skill_names(manifest_path) or normalize_skill_names(
        sorted(path.name for path in skills_dir.iterdir() if (path / "SKILL.md").is_file())
    )
    if not names:
        raise UpdateError("archive does not declare any managed skills")
    return names


def remove_path(path: Path) -> None:
    """删除文件、符号链接或目录；路径不存在则什么都不做。"""
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    elif path.exists() or path.is_symlink():
        path.unlink()


def install_updater(extract_dir: Path, root: Path) -> None:
    """同步发布包里的 updater，并清理旧 shell updater。"""
    source = extract_dir / UPDATER_PATH
    destination = root / UPDATER_PATH
    destination.parent.mkdir(parents=True, exist_ok=True)

    if source.is_file():
        shutil.copy2(source, destination)
        destination.chmod(destination.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    remove_path(root / LEGACY_UPDATER_PATH)


def write_manifest(source_manifest: Path, target_manifest: Path, version: str | None, names: list[str]) -> None:
    """写入目标项目 manifest，供下次更新判断哪些 skills 归本脚本管理。"""
    data = read_json(source_manifest)
    data.update(
        {
            "source": f"github.com/{DEFAULT_REPO}",
            "repo": DEFAULT_REPO,
            "asset": ASSET_NAME,
            "installedAt": utc_timestamp(),
            "managedSkills": sorted(normalize_skill_names(data.get("managedSkills") or names)),
        }
    )
    if version:
        data["version"] = version

    target_manifest.parent.mkdir(parents=True, exist_ok=True)
    target_manifest.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def install_package(root: Path, extract_dir: Path, version: str | None) -> str:
    """把已经解压的发布包安装到目标项目，并返回安装版本号。"""
    source_manifest = extract_dir / MANIFEST_PATH
    source_skills = extract_dir / SKILLS_PATH
    target_manifest = root / MANIFEST_PATH
    target_skills = root / SKILLS_PATH

    if not source_skills.is_dir():
        raise UpdateError("archive does not contain .codex/skills")

    new_names = incoming_skill_names(source_manifest, source_skills)
    # 当前 manifest 存在时，用它判断旧版 managed skills；首次安装时用新包列表兜底。
    old_names = manifest_skill_names(target_manifest) or new_names
    target_skills.mkdir(parents=True, exist_ok=True)

    # 只替换 manifest 记录的 managed skills，避免误删用户自己的本地 skills。
    for name in old_names:
        remove_path(target_skills / name)
    for name in new_names:
        source = source_skills / name
        if not source.is_dir():
            raise UpdateError(f"managed skill missing from archive: {name}")
        remove_path(target_skills / name)
        shutil.copytree(source, target_skills / name)

    install_updater(extract_dir, root)
    # manifest 最后写入；如果前面的复制失败，就不会记录一个半安装状态。
    write_manifest(source_manifest, target_manifest, version, new_names)
    return str(read_json(target_manifest).get("version", "unknown"))


def run() -> int:
    """脚本入口：临时目录中完成下载/解压，再安装到项目根目录。"""
    args = parse_args()
    try:
        with tempfile.TemporaryDirectory(prefix="flutter-mvvm-skills-") as tmp:
            tmp_dir = Path(tmp)
            archive_path = tmp_dir / ASSET_NAME
            extract_dir = tmp_dir / "extract"

            download_archive(args.version, archive_path)
            extract_archive(archive_path, extract_dir)
            installed_version = install_package(project_root(), extract_dir, args.version)
    except UpdateError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"Updated Flutter MVVM Codex skills to {installed_version}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
