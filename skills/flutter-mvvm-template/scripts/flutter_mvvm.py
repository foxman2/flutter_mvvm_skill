#!/usr/bin/env python3
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
from pathlib import Path


PROJECT_NAME_RE = re.compile(r"^[a-z][a-z0-9_]*$")
PACKAGE_NAME_RE = re.compile(r"^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$")
TEXT_SUFFIXES = {
    ".arb",
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
PROJECT_SKILLS_REPO = "foxman2/flutter_mvvm_skill"
PROJECT_SKILLS_ASSET = "flutter-mvvm-skills.tar.gz"


class CliError(Exception):
    pass


def skill_root() -> Path:
    return Path(__file__).resolve().parents[1]


def repo_root() -> Path:
    return skill_root().parents[1]


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


def validate_package_name(name: str) -> None:
    if not PACKAGE_NAME_RE.match(name):
        raise CliError(
            "Invalid package name. Use lowercase dot-separated segments, "
            "for example com.example.myapp."
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


def prompt_required(label: str, default: str | None = None) -> str:
    if not sys.stdin.isatty():
        raise CliError(
            f"{label} is required. Pass it as an argument when running non-interactively."
        )
    suffix = f" [{default}]" if default else ""
    value = input(f"{label}{suffix}: ").strip()
    if value:
        return value
    if default:
        return default
    raise CliError(f"{label} is required.")


def project_name_from_package_name(package_name: str) -> str:
    segment = package_name.rsplit(".", 1)[-1]
    name = re.sub(r"[^a-z0-9_]+", "_", segment.lower()).strip("_")
    if not name or not re.match(r"^[a-z]", name):
        name = f"app_{name}" if name else "app"
    validate_project_name(name)
    return name


def package_name_from_org(org: str, project_name: str) -> str:
    return f"{org}.{project_name}"


def suggested_package_name_from_project(org: str, project_name: str) -> str:
    return f"{org}.{project_name.replace('_', '')}"


def org_from_package_name(package_name: str) -> str:
    return package_name.rsplit(".", 1)[0]


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
            if item.name == "scripts":
                shutil.copytree(item, destination, dirs_exist_ok=True)
                continue
            if destination.exists():
                shutil.rmtree(destination)
            shutil.copytree(item, destination)
        else:
            shutil.copy2(item, destination)

    replace_placeholders(target_dir, replacements)


def copy_project_skills(target_dir: Path) -> list[str]:
    source_dir = repo_root() / "project-skills"
    if not source_dir.is_dir():
        raise CliError(f"Project skills directory was not found: {source_dir}")

    skills_dir = target_dir / ".codex" / "skills"
    skills_dir.mkdir(parents=True, exist_ok=True)

    managed_skills: list[str] = []
    for skill_dir in sorted(source_dir.iterdir()):
        if not skill_dir.is_dir() or not (skill_dir / "SKILL.md").is_file():
            continue

        managed_skills.append(skill_dir.name)
        destination = skills_dir / skill_dir.name
        if destination.exists():
            shutil.rmtree(destination)
        shutil.copytree(skill_dir, destination, ignore=ignored_project_asset_names)

    if not managed_skills:
        raise CliError(f"No project skills were found in: {source_dir}")
    return managed_skills


def ignored_project_asset_names(directory: str, names: list[str]) -> set[str]:
    ignored: set[str] = set()
    for name in names:
        path = Path(directory) / name
        if name in EXCLUDED_FILE_NAMES:
            ignored.add(name)
        elif path.is_dir() and name in EXCLUDED_DIR_NAMES:
            ignored.add(name)
        elif path.is_file() and path.suffix in EXCLUDED_SUFFIXES:
            ignored.add(name)
    return ignored


def ensure_update_script(target_dir: Path) -> None:
    destination = target_dir / "scripts" / "update-codex-skills.py"
    if not destination.is_file():
        raise CliError(f"Codex skills updater was not copied from template assets: {destination}")
    destination.chmod(destination.stat().st_mode | 0o755)

    legacy_shell = target_dir / "scripts" / "update-codex-skills.sh"
    if legacy_shell.exists() or legacy_shell.is_symlink():
        legacy_shell.unlink()


def write_project_skills_manifest(target_dir: Path, managed_skills: list[str]) -> None:
    manifest_dir = target_dir / ".codex"
    manifest_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "source": f"github.com/{PROJECT_SKILLS_REPO}",
        "repo": PROJECT_SKILLS_REPO,
        "asset": PROJECT_SKILLS_ASSET,
        "version": release_tag_from_plugin_version(),
        "installedAt": utc_timestamp(),
        "managedSkills": managed_skills,
    }
    (manifest_dir / "flutter-mvvm-skills.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def release_tag_from_plugin_version() -> str:
    manifest_path = repo_root() / ".codex-plugin" / "plugin.json"
    if not manifest_path.is_file():
        return "unknown"

    try:
        version = json.loads(manifest_path.read_text(encoding="utf-8"))["version"]
    except (KeyError, json.JSONDecodeError):
        return "unknown"

    base_version = str(version).split("+", 1)[0]
    return base_version if base_version.startswith("v") else f"v{base_version}"


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


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


def read_pubspec_patch(patch_file: Path) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {}
    current_section: str | None = None
    for raw_line in patch_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue
        if not raw_line.startswith(" ") and line.endswith(":"):
            current_section = line.removesuffix(":")
            sections[current_section] = []
            continue
        if current_section is not None:
            sections[current_section].append(line)
    return sections


def child_blocks(section_lines: list[str]) -> list[tuple[str, list[str]]]:
    blocks: list[tuple[str, list[str]]] = []
    current_name: str | None = None
    current_block: list[str] = []

    def flush() -> None:
        nonlocal current_name, current_block
        if current_name is not None:
            blocks.append((current_name, current_block))
        current_name = None
        current_block = []

    for line in section_lines:
        match = re.match(r"^  ([a-zA-Z0-9_]+):", line)
        if match:
            flush()
            current_name = match.group(1)
            current_block = [line]
        elif current_name is not None:
            current_block.append(line)
    flush()
    return blocks


def section_bounds(lines: list[str], section: str) -> tuple[int, int] | None:
    header = f"{section}:"
    for index, line in enumerate(lines):
        if line == header:
            start = index + 1
            end = len(lines)
            for next_index in range(start, len(lines)):
                next_line = lines[next_index]
                if (
                    next_line.strip()
                    and not next_line.startswith(" ")
                    and not next_line.lstrip().startswith("#")
                ):
                    end = next_index
                    break
            return start, end
    return None


def direct_child_names(lines: list[str]) -> set[str]:
    names = set()
    for line in lines:
        match = re.match(r"^  ([a-zA-Z0-9_]+):", line)
        if match:
            names.add(match.group(1))
    return names


def merge_pubspec_patch(pubspec_file: Path, patch_file: Path) -> None:
    patch = read_pubspec_patch(patch_file)
    text = pubspec_file.read_text(encoding="utf-8")
    lines = text.splitlines()

    for section, section_lines in patch.items():
        blocks = child_blocks(section_lines)
        bounds = section_bounds(lines, section)
        if bounds is None:
            if lines and lines[-1].strip():
                lines.append("")
            lines.append(f"{section}:")
            for _, block in blocks:
                lines.extend(block)
            continue

        start, end = bounds
        existing = direct_child_names(lines[start:end])
        additions = [
            line
            for name, block in blocks
            if name not in existing
            for line in block
        ]
        if not additions:
            continue

        if section == "dependencies":
            insert_at = end
            while insert_at > start and not lines[insert_at - 1].strip():
                insert_at -= 1
            insert_lines = additions if insert_at < end else additions + [""]
            lines[insert_at:insert_at] = insert_lines
        else:
            insert_lines = (
                additions
                if start < len(lines) and not lines[start].strip()
                else additions + [""]
            )
            lines[start:start] = insert_lines

    pubspec_file.write_text("\n".join(lines) + "\n", encoding="utf-8")


def resolve_create_inputs(args: argparse.Namespace) -> tuple[str, str, str | None]:
    app_name = args.app_name
    package_name = args.package_name
    project_name = args.project_name

    should_prompt = project_name is None or app_name is None or package_name is None
    if should_prompt and sys.stdin.isatty():
        if app_name is None:
            app_name = prompt_required("App name")
        if package_name is None:
            default_package = (
                suggested_package_name_from_project(args.org, project_name)
                if project_name is not None
                else None
            )
            package_name = prompt_required("Package name", default_package)

    if package_name is not None:
        validate_package_name(package_name)

    if project_name is None:
        if package_name is None:
            raise CliError(
                "project_name or --package-name is required when running non-interactively."
            )
        project_name = project_name_from_package_name(package_name)

    validate_project_name(project_name)

    if app_name is None:
        app_name = title_from_project_name(project_name)

    return project_name, app_name, package_name


def create_project(args: argparse.Namespace) -> None:
    project_name, app_name, package_name = resolve_create_inputs(args)
    platforms = validate_platforms(args.platforms)
    ensure_flutter()

    output_dir = Path(args.output).expanduser().resolve()
    target_dir = output_dir / project_name
    if target_dir.exists() and any(target_dir.iterdir()):
        raise CliError(
            f"Target directory is not empty: {target_dir}. "
            "Choose a new project name or an empty output directory."
        )

    output_dir.mkdir(parents=True, exist_ok=True)
    create_org = org_from_package_name(package_name) if package_name else args.org

    create_cmd = [
        "flutter",
        "create",
        project_name,
        "--org",
        create_org,
        "--platforms",
        platforms,
    ]
    run(create_cmd, cwd=output_dir)

    overlay_dir = skill_root() / "assets" / "flutter_mvvm_overlay"
    replacements = {
        "{{project_name}}": project_name,
        "{{app_name}}": app_name,
        "{{org}}": create_org,
        "{{package_name}}": package_name or package_name_from_org(create_org, project_name),
        "{{package_import}}": project_name,
    }
    copy_overlay(overlay_dir, target_dir, replacements)
    apply_native_identity(target_dir, app_name, package_name)
    merge_pubspec_patch(
        target_dir / "pubspec.yaml",
        overlay_dir / "template_pubspec_patch.yaml",
    )
    managed_skills = copy_project_skills(target_dir)
    ensure_update_script(target_dir)
    write_project_skills_manifest(target_dir, managed_skills)

    pub_get_code = run(["flutter", "pub", "get"], cwd=target_dir, allow_failure=True)
    if pub_get_code != 0:
        print(
            "flutter pub get failed. The project files were generated; "
            "run it manually after network/tooling is available."
        )
        return

    if not args.skip_final_checks:
        run(["dart", "format", "lib", "test"], cwd=target_dir, allow_failure=True)
        run(["flutter", "analyze"], cwd=target_dir, allow_failure=True)

    print(f"Created Flutter MVVM project at {target_dir}")


def apply_native_identity(
    target_dir: Path,
    app_name: str,
    package_name: str | None,
) -> None:
    apply_android_identity(target_dir, app_name, package_name)
    apply_ios_identity(target_dir, app_name, package_name)
    apply_web_identity(target_dir, app_name)


def apply_android_identity(
    target_dir: Path,
    app_name: str,
    package_name: str | None,
) -> None:
    gradle_file = target_dir / "android" / "app" / "build.gradle.kts"
    if package_name is not None and gradle_file.exists():
        text = gradle_file.read_text(encoding="utf-8")
        text = re.sub(r'namespace = "[^"]+"', f'namespace = "{package_name}"', text)
        text = re.sub(
            r'applicationId = "[^"]+"',
            f'applicationId = "{package_name}"',
            text,
        )
        gradle_file.write_text(text, encoding="utf-8")

    manifest_file = (
        target_dir
        / "android"
        / "app"
        / "src"
        / "main"
        / "AndroidManifest.xml"
    )
    if manifest_file.exists():
        text = manifest_file.read_text(encoding="utf-8")
        text = re.sub(
            r'android:label="[^"]*"',
            f'android:label="{xml_attribute_escape(app_name)}"',
            text,
            count=1,
        )
        manifest_file.write_text(text, encoding="utf-8")

    if package_name is not None:
        move_android_main_activity(target_dir, package_name)


def move_android_main_activity(target_dir: Path, package_name: str) -> None:
    kotlin_root = target_dir / "android" / "app" / "src" / "main" / "kotlin"
    if not kotlin_root.exists():
        return
    activities = list(kotlin_root.rglob("MainActivity.kt"))
    if not activities:
        return
    source = activities[0]
    destination = kotlin_root.joinpath(*package_name.split("."), "MainActivity.kt")
    destination.parent.mkdir(parents=True, exist_ok=True)
    text = source.read_text(encoding="utf-8")
    text = re.sub(
        r"^package .+$",
        f"package {package_name}",
        text,
        count=1,
        flags=re.MULTILINE,
    )
    destination.write_text(text, encoding="utf-8")
    if source != destination:
        source.unlink()
        remove_empty_parents(source.parent, kotlin_root)


def remove_empty_parents(path: Path, stop: Path) -> None:
    while path != stop and path.exists():
        try:
            path.rmdir()
        except OSError:
            return
        path = path.parent


def apply_ios_identity(
    target_dir: Path,
    app_name: str,
    package_name: str | None,
) -> None:
    info_plist = target_dir / "ios" / "Runner" / "Info.plist"
    if info_plist.exists():
        with info_plist.open("rb") as file:
            data = plistlib.load(file)
        data["CFBundleDisplayName"] = app_name
        data["CFBundleName"] = app_name
        with info_plist.open("wb") as file:
            plistlib.dump(data, file, sort_keys=False)

    project_file = target_dir / "ios" / "Runner.xcodeproj" / "project.pbxproj"
    if package_name is not None and project_file.exists():
        lines = []
        for line in project_file.read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if stripped.startswith("PRODUCT_BUNDLE_IDENTIFIER = "):
                current = stripped.removeprefix(
                    "PRODUCT_BUNDLE_IDENTIFIER = "
                ).removesuffix(";")
                suffix = ".RunnerTests" if current.endswith(".RunnerTests") else ""
                indent = line[: len(line) - len(line.lstrip())]
                line = f"{indent}PRODUCT_BUNDLE_IDENTIFIER = {package_name}{suffix};"
            lines.append(line)
        project_file.write_text("\n".join(lines) + "\n", encoding="utf-8")


def apply_web_identity(target_dir: Path, app_name: str) -> None:
    manifest_file = target_dir / "web" / "manifest.json"
    if manifest_file.exists():
        data = json.loads(manifest_file.read_text(encoding="utf-8"))
        data["name"] = app_name
        data["short_name"] = app_name
        manifest_file.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")

    index_file = target_dir / "web" / "index.html"
    if index_file.exists():
        escaped_name = html_text_escape(app_name)
        text = index_file.read_text(encoding="utf-8")
        text = re.sub(
            r'<meta name="apple-mobile-web-app-title" content="[^"]*">',
            f'<meta name="apple-mobile-web-app-title" content="{xml_attribute_escape(app_name)}">',
            text,
            count=1,
        )
        text = re.sub(
            r"<title>.*?</title>",
            f"<title>{escaped_name}</title>",
            text,
            count=1,
        )
        index_file.write_text(text, encoding="utf-8")


def xml_attribute_escape(value: str) -> str:
    return (
        value.replace("&", "&amp;")
        .replace('"', "&quot;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def html_text_escape(value: str) -> str:
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def title_from_project_name(name: str) -> str:
    return " ".join(part.capitalize() for part in name.split("_"))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="flutter-mvvm")
    subparsers = parser.add_subparsers(dest="command", required=True)

    create = subparsers.add_parser("create", help="Create a Flutter MVVM app from the bundled template.")
    create.add_argument("project_name", nargs="?")
    create.add_argument("--org", default="com.example")
    create.add_argument("--platforms", default="ios,android,web")
    create.add_argument("--output", default=".")
    create.add_argument("--app-name")
    create.add_argument("--package-name")
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
