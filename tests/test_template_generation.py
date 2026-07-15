from __future__ import annotations

import importlib.util
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
GENERATOR_PATH = ROOT / "skills/flutter-mvvm-template/scripts/flutter_mvvm.py"
OVERLAY_TEST_PATH = (
    ROOT / "skills/flutter-mvvm-template/assets/flutter_mvvm_overlay/test"
)
CONTRACT_TEST_PATH = ROOT / "tests/template_contract"


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


class TemplateGenerationUnitTests(unittest.TestCase):
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
            self.run_command(["flutter", "analyze"], cwd=project)
            self.run_command(
                ["flutter", "test", "test/app_smoke_test.dart"],
                cwd=project,
            )

            for source in CONTRACT_TEST_PATH.glob("*.dart"):
                content = source.read_text(encoding="utf-8").replace(
                    "{{project_name}}",
                    project_name,
                )
                (project / "test" / source.name).write_text(content, encoding="utf-8")

            self.run_command(
                ["dart", "format", "--output=none", "--set-exit-if-changed", "test"],
                cwd=project,
            )
            self.run_command(["flutter", "test"], cwd=project)


if __name__ == "__main__":
    unittest.main()
