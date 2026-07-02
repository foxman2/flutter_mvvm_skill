#!/usr/bin/env python3
from __future__ import annotations

import argparse
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
    if target_dir.exists() and any(target_dir.iterdir()) and not args.force:
        raise CliError(
            f"Target directory is not empty: {target_dir}. "
            "Use --force to overwrite template files."
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
    if args.force:
        create_cmd.append("--overwrite")
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
    merge_pubspec_dependencies(
        target_dir / "pubspec.yaml",
        overlay_dir / "template_pubspec_patch.yaml",
    )

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
