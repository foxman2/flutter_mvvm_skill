from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
GENERATOR_PATH = ROOT / "skills/flutter-mvvm-template/scripts/flutter_mvvm.py"
OVERLAY_PATH = ROOT / "skills/flutter-mvvm-template/assets/flutter_mvvm_overlay"
OVERLAY_TEST_PATH = OVERLAY_PATH / "test"
CONTRACT_TEST_PATH = ROOT / "tests/template_contract"
PROJECT_SKILLS = (
    "flutter-mvvm-api-dev",
    "flutter-mvvm-feature-dev",
    "flutter-mvvm-inspector",
    "flutter-mvvm-mock-api-dev",
    "flutter-mvvm-pm-ui",
)
ARCHITECTURE_PROJECT_SKILLS = tuple(
    skill_name
    for skill_name in PROJECT_SKILLS
    if skill_name != "flutter-mvvm-inspector"
)
REMOVED_ARCHITECTURE_REFERENCES = (
    "App" + "Services",
    "app_" + "services.dart",
    "ApiService." + "shared",
    "AuthRepository." + "shared",
)
LEGACY_APP_SERVICES_FILE = "app_" + "services.dart"


def load_generator():
    spec = importlib.util.spec_from_file_location(
        "flutter_mvvm_template_generator_test",
        GENERATOR_PATH,
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load module: {GENERATOR_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


generator = load_generator()


def directory_snapshot(root: Path) -> dict[str, bytes]:
    return {
        path.relative_to(root).as_posix(): path.read_bytes()
        for path in sorted(root.rglob("*"))
        if path.is_file() and "__pycache__" not in path.parts and path.suffix != ".pyc"
    }


def searchable_text(root: Path) -> str:
    contents: list[str] = []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or "__pycache__" in path.parts or path.suffix == ".pyc":
            continue
        try:
            contents.append(path.read_text(encoding="utf-8"))
        except UnicodeDecodeError:
            continue
    return "\n".join(contents)


class TemplateGenerationUnitTests(unittest.TestCase):
    def test_overlay_uses_app_container_architecture(self) -> None:
        lib = OVERLAY_PATH / "lib"

        self.assertTrue((lib / "app_container.dart").is_file())
        self.assertFalse((lib / "services" / LEGACY_APP_SERVICES_FILE).exists())
        for removed in REMOVED_ARCHITECTURE_REFERENCES:
            self.assertNotIn(removed, searchable_text(OVERLAY_PATH))

    def test_default_overlay_contains_only_smoke_test(self) -> None:
        generated_tests = sorted(path.name for path in OVERLAY_TEST_PATH.glob("*.dart"))
        contract_tests = sorted(path.name for path in CONTRACT_TEST_PATH.glob("*.dart"))

        self.assertEqual(generated_tests, ["app_smoke_test.dart"])
        self.assertEqual(
            contract_tests,
            [
                "api_service_test.dart",
                "mvvm_test.dart",
                "navigation_test.dart",
                "widget_test.dart",
            ],
        )

    def test_final_checks_run_format_analyze_and_smoke_test(self) -> None:
        target = Path("/tmp/generated-flutter-mvvm-app")

        with mock.patch.object(generator, "run", return_value=0) as run:
            generator.run_final_checks(target)

        self.assertEqual(
            run.call_args_list,
            [
                mock.call(
                    ["dart", "format", "lib", "test"],
                    cwd=target,
                    allow_failure=True,
                ),
                mock.call(["flutter", "analyze"], cwd=target, allow_failure=True),
                mock.call(
                    ["flutter", "test", "test/app_smoke_test.dart"],
                    cwd=target,
                    allow_failure=True,
                ),
            ],
        )


@unittest.skipUnless(shutil.which("flutter"), "Flutter is required for template integration tests")
class TemplateGenerationIntegrationTests(unittest.TestCase):
    def run_command(self, command: list[str], *, cwd: Path | None = None) -> None:
        completed = subprocess.run(
            command,
            cwd=str(cwd) if cwd else None,
            capture_output=True,
            text=True,
        )
        if completed.returncode != 0:
            self.fail(
                f"command failed ({completed.returncode}): {' '.join(command)}\n"
                f"stdout:\n{completed.stdout}\n"
                f"stderr:\n{completed.stderr}"
            )

    def test_generated_project_smoke_and_full_contract_suite(self) -> None:
        project_name = "template_contract_app"
        with tempfile.TemporaryDirectory(prefix="flutter-mvvm-template-test-") as temporary:
            output = Path(temporary)
            self.run_command(
                [
                    sys.executable,
                    str(GENERATOR_PATH),
                    "create",
                    project_name,
                    "--app-name",
                    "Template Contract App",
                    "--package-name",
                    "com.example.templatecontractapp",
                    "--output",
                    str(output),
                    "--skip-final-checks",
                ]
            )
            project = output / project_name

            self.assertEqual(
                sorted(path.name for path in (project / "test").glob("*.dart")),
                ["app_smoke_test.dart"],
            )
            self.assertTrue((project / "lib/app_container.dart").is_file())
            self.assertFalse(
                (project / "lib/services" / LEGACY_APP_SERVICES_FILE).exists()
            )

            manifest = json.loads(
                (project / ".codex/flutter-mvvm-skills.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(manifest["managedSkills"], list(PROJECT_SKILLS))

            for skill_name in PROJECT_SKILLS:
                self.assertEqual(
                    directory_snapshot(ROOT / "project-skills" / skill_name),
                    directory_snapshot(project / ".codex/skills" / skill_name),
                )

            for source in CONTRACT_TEST_PATH.glob("*.dart"):
                content = source.read_text(encoding="utf-8").replace(
                    "{{project_name}}",
                    project_name,
                )
                (project / "test" / source.name).write_text(content, encoding="utf-8")

            self.run_command(
                [
                    "dart",
                    "format",
                    "--output=none",
                    "--set-exit-if-changed",
                    "lib",
                    "test",
                ],
                cwd=project,
            )
            self.run_command(["flutter", "analyze"], cwd=project)
            self.run_command(["flutter", "test"], cwd=project)

            generated_architecture = "\n".join(
                [
                    searchable_text(project / "lib"),
                    *[
                        searchable_text(project / ".codex/skills" / skill_name)
                        for skill_name in ARCHITECTURE_PROJECT_SKILLS
                    ],
                ]
            )
            for removed in REMOVED_ARCHITECTURE_REFERENCES:
                self.assertNotIn(removed, generated_architecture)


if __name__ == "__main__":
    unittest.main()
