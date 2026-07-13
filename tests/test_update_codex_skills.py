from __future__ import annotations

from contextlib import redirect_stderr
import importlib.util
import io
import json
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
UPDATER_PATH = (
    ROOT
    / "skills"
    / "flutter-mvvm-template"
    / "assets"
    / "flutter_mvvm_overlay"
    / "scripts"
    / "update-codex-skills.py"
)
GENERATOR_PATH = ROOT / "skills" / "flutter-mvvm-template" / "scripts" / "flutter_mvvm.py"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load module: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


updater = load_module("update_codex_skills", UPDATER_PATH)
generator = load_module("flutter_mvvm_generator", GENERATOR_PATH)


def run_git(*args: str, cwd: Path | None = None) -> str:
    completed = subprocess.run(
        ["git", *args],
        cwd=str(cwd) if cwd else None,
        check=True,
        capture_output=True,
        text=True,
    )
    return completed.stdout.strip()


def write_skill(root: Path, name: str, marker: str) -> None:
    skill_dir = root / "project-skills" / name
    skill_dir.mkdir(parents=True, exist_ok=True)
    (skill_dir / "SKILL.md").write_text(
        "\n".join(
            [
                "---",
                f"name: {name}",
                "description: Test fixture skill.",
                "---",
                "",
                f"# {name}",
                "",
                marker,
                "",
            ]
        ),
        encoding="utf-8",
    )


def write_source_state(
    root: Path,
    *,
    version: str,
    skills: dict[str, str],
    updater_marker: str,
) -> None:
    skills_dir = root / "project-skills"
    if skills_dir.exists():
        shutil.rmtree(skills_dir)
    for name, marker in skills.items():
        write_skill(root, name, marker)

    plugin_dir = root / ".codex-plugin"
    plugin_dir.mkdir(parents=True, exist_ok=True)
    (plugin_dir / "plugin.json").write_text(
        json.dumps({"name": "flutter-mvvm-devkit", "version": version}) + "\n",
        encoding="utf-8",
    )

    updater_path = root / updater.SOURCE_UPDATER_PATH
    updater_path.parent.mkdir(parents=True, exist_ok=True)
    updater_path.write_text(f"#!/usr/bin/env python3\n# {updater_marker}\n", encoding="utf-8")

    unused = root / "unused" / "not-installed.txt"
    unused.parent.mkdir(parents=True, exist_ok=True)
    unused.write_text(f"unused {version}\n", encoding="utf-8")
    (root / "README.md").write_text(f"source {version}\n", encoding="utf-8")


def write_target_skill(skills_dir: Path, name: str, marker: str) -> None:
    destination = skills_dir / name
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "SKILL.md").write_text(marker + "\n", encoding="utf-8")


def snapshot(root: Path) -> dict[str, bytes | None]:
    if not root.exists():
        return {}
    result: dict[str, bytes | None] = {}
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root).as_posix()
        result[relative] = None if path.is_dir() else path.read_bytes()
    return result


class UpdateCodexSkillsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="update-codex-skills-test-")
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.repository = self.base / "source-repository"
        run_git("init", "--initial-branch=main", str(self.repository))
        run_git("config", "user.name", "Codex Test", cwd=self.repository)
        run_git("config", "user.email", "codex@example.invalid", cwd=self.repository)
        run_git("config", "uploadpack.allowFilter", "true", cwd=self.repository)

        write_source_state(
            self.repository,
            version="0.1.0",
            skills={"shared-skill": "tag shared", "tag-only-skill": "tag only"},
            updater_marker="tag updater",
        )
        self.commit("tag source")
        run_git("tag", "v0.1.0", cwd=self.repository)

        write_source_state(
            self.repository,
            version="0.2.0",
            skills={"main-only-skill": "main only", "shared-skill": "main shared"},
            updater_marker="main updater",
        )
        self.commit("main source")
        self.repository_url = self.repository.as_uri()

    def commit(self, message: str) -> None:
        run_git("add", "--all", cwd=self.repository)
        run_git("commit", "--message", message, cwd=self.repository)

    def target_with_sentinel(self) -> Path:
        target = self.base / "target-project"
        target.mkdir(exist_ok=True)
        (target / "sentinel.txt").write_text("unchanged\n", encoding="utf-8")
        return target

    def test_main_uses_shallow_sparse_checkout(self) -> None:
        checkout = self.base / "main-checkout"
        updater.clone_source(checkout, "main", self.repository_url)
        package = updater.inspect_source(checkout)

        self.assertEqual(package.version, "0.2.0")
        self.assertEqual(package.skill_names, ("main-only-skill", "shared-skill"))
        self.assertEqual(run_git("rev-parse", "--is-shallow-repository", cwd=checkout), "true")
        self.assertFalse((checkout / "unused" / "not-installed.txt").exists())
        self.assertFalse((checkout / "README.md").exists())
        self.assertTrue((checkout / updater.SOURCE_UPDATER_PATH).is_file())

    def test_tag_uses_shallow_sparse_checkout(self) -> None:
        checkout = self.base / "tag-checkout"
        updater.clone_source(checkout, "v0.1.0", self.repository_url)
        package = updater.inspect_source(checkout)

        self.assertEqual(package.version, "0.1.0")
        self.assertEqual(package.skill_names, ("shared-skill", "tag-only-skill"))
        self.assertIn("tag shared", (checkout / "project-skills/shared-skill/SKILL.md").read_text())
        self.assertEqual(run_git("rev-parse", "--is-shallow-repository", cwd=checkout), "true")
        self.assertFalse((checkout / "unused" / "not-installed.txt").exists())
        self.assertFalse((checkout / "README.md").exists())

    def test_invalid_tag_is_rejected_before_update(self) -> None:
        target = self.target_with_sentinel()
        before = snapshot(target)
        stderr = io.StringIO()
        with mock.patch.object(updater, "project_root", return_value=target), mock.patch.object(
            updater, "update_project"
        ) as update_project, redirect_stderr(stderr):
            result = updater.run(["--version", "0.1.0"])

        self.assertEqual(result, 1)
        update_project.assert_not_called()
        self.assertIn("invalid version tag", stderr.getvalue())
        self.assertEqual(snapshot(target), before)

    def test_prerelease_tag_format_is_supported(self) -> None:
        self.assertEqual(updater.validate_requested_ref("v1.2.3-rc.1"), "v1.2.3-rc.1")
        for invalid in ("main", "v1", "v1.2", "v01.2.3", "v1.2.3-"):
            with self.subTest(invalid=invalid), self.assertRaises(updater.UpdateError):
                updater.validate_requested_ref(invalid)

    def test_missing_git_does_not_modify_target(self) -> None:
        target = self.target_with_sentinel()
        before = snapshot(target)
        with mock.patch.object(updater.shutil, "which", return_value=None), self.assertRaisesRegex(
            updater.UpdateError, "git is required"
        ):
            updater.update_project(target, "main", self.repository_url)
        self.assertEqual(snapshot(target), before)

    def test_missing_tag_does_not_modify_target(self) -> None:
        target = self.target_with_sentinel()
        before = snapshot(target)
        with self.assertRaisesRegex(updater.UpdateError, "git clone failed"):
            updater.update_project(target, "v9.9.9", self.repository_url)
        self.assertEqual(snapshot(target), before)

    def test_invalid_source_does_not_modify_target(self) -> None:
        (self.repository / "project-skills/shared-skill/SKILL.md").unlink()
        (self.repository / "project-skills/shared-skill/BROKEN.txt").write_text(
            "missing SKILL.md\n", encoding="utf-8"
        )
        self.commit("break source structure")
        target = self.target_with_sentinel()
        target_skill = target / ".codex" / "skills" / "existing-skill" / "SKILL.md"
        target_skill.parent.mkdir(parents=True)
        target_skill.write_text("existing\n", encoding="utf-8")
        before = snapshot(target)

        with self.assertRaisesRegex(updater.UpdateError, "invalid source structure"):
            updater.update_project(target, "main", self.repository_url)
        self.assertEqual(snapshot(target), before)

    def test_update_replaces_and_removes_managed_skills_but_preserves_local_skills(self) -> None:
        target = self.target_with_sentinel()
        skills_dir = target / ".codex" / "skills"
        for name, marker in {
            "retired-skill": "old managed",
            "shared-skill": "old shared",
            "local-skill": "user local",
        }.items():
            write_target_skill(skills_dir, name, marker)
        manifest_path = target / updater.MANIFEST_PATH
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text(
            json.dumps(
                {
                    "asset": "old-release-file.tar.gz",
                    "version": "v0.1.0",
                    "managedSkills": ["retired-skill", "shared-skill"],
                }
            ),
            encoding="utf-8",
        )
        legacy_updater = target / updater.LEGACY_UPDATER_PATH
        legacy_updater.parent.mkdir(parents=True, exist_ok=True)
        legacy_updater.write_text("legacy\n", encoding="utf-8")

        package = updater.update_project(target, "main", self.repository_url)

        self.assertEqual(package.version, "0.2.0")
        self.assertFalse((skills_dir / "retired-skill").exists())
        self.assertIn("main shared", (skills_dir / "shared-skill/SKILL.md").read_text())
        self.assertTrue((skills_dir / "main-only-skill/SKILL.md").is_file())
        self.assertEqual((skills_dir / "local-skill/SKILL.md").read_text(), "user local\n")
        self.assertFalse(legacy_updater.exists())

        installed_updater = target / updater.TARGET_UPDATER_PATH
        self.assertIn("main updater", installed_updater.read_text())
        self.assertTrue(installed_updater.stat().st_mode & stat.S_IXUSR)

        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        self.assertNotIn("asset", manifest)
        self.assertEqual(manifest["ref"], "main")
        self.assertEqual(manifest["version"], "0.2.0")
        self.assertEqual(manifest["managedSkills"], ["main-only-skill", "shared-skill"])
        self.assertRegex(manifest["installedAt"], r"^\d{4}-\d{2}-\d{2}T.*Z$")

    def test_tag_update_records_tag_and_declared_source_version(self) -> None:
        target = self.target_with_sentinel()
        updater.update_project(target, "v0.1.0", self.repository_url)

        manifest = json.loads((target / updater.MANIFEST_PATH).read_text(encoding="utf-8"))
        self.assertEqual(manifest["ref"], "v0.1.0")
        self.assertEqual(manifest["version"], "0.1.0")
        self.assertIn(
            "tag shared",
            (target / updater.TARGET_SKILLS_PATH / "shared-skill/SKILL.md").read_text(),
        )

    def test_removed_cli_option_is_not_accepted(self) -> None:
        with redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            updater.parse_args(["--archive", "skills.tar.gz"])

    def test_generated_project_manifest_uses_ref_without_asset(self) -> None:
        target = self.base / "generated-project"
        source = self.base / "generator-source"
        plugin_manifest = source / ".codex-plugin" / "plugin.json"
        plugin_manifest.parent.mkdir(parents=True)
        plugin_manifest.write_text(json.dumps({"version": "9.8.7"}), encoding="utf-8")
        with mock.patch.object(generator, "repo_root", return_value=source):
            generator.write_project_skills_manifest(target, ["shared-skill"])
        manifest = json.loads((target / updater.MANIFEST_PATH).read_text(encoding="utf-8"))

        self.assertNotIn("asset", manifest)
        self.assertEqual(manifest["version"], "9.8.7")
        self.assertEqual(manifest["ref"], "v9.8.7")


if __name__ == "__main__":
    unittest.main()
