from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import re
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
PM_UI_SKILL_PATH = ROOT / "project-skills/flutter-mvvm-pm-ui"
MARKETPLACE_PM_UI_SKILL_PATH = (
    ROOT / "plugins/flutter-mvvm-devkit/project-skills/flutter-mvvm-pm-ui"
)
FEATURE_DEV_SKILL_PATH = ROOT / "project-skills/flutter-mvvm-feature-dev"
INSPECTOR_SKILL_PATH = ROOT / "project-skills/flutter-mvvm-inspector"
MOCK_API_DEV_SKILL_PATH = ROOT / "project-skills/flutter-mvvm-mock-api-dev"
API_DEV_SKILL_PATH = ROOT / "project-skills/flutter-mvvm-api-dev"
MARKETPLACE_API_DEV_SKILL_PATH = (
    ROOT / "plugins/flutter-mvvm-devkit/project-skills/flutter-mvvm-api-dev"
)
CODE_MAP_SKILL_PATH = ROOT / "project-skills/feature-code-map"
MARKETPLACE_CODE_MAP_SKILL_PATH = (
    ROOT / "plugins/flutter-mvvm-devkit/project-skills/feature-code-map"
)
CODE_QUALITY_SKILL_PATH = ROOT / "project-skills/code-quality"
MARKETPLACE_CODE_QUALITY_SKILL_PATH = (
    ROOT / "plugins/flutter-mvvm-devkit/project-skills/code-quality"
)
MARKETPLACE_PROJECT_SKILLS_PATH = (
    ROOT / "plugins/flutter-mvvm-devkit/project-skills"
)
MARKETPLACE_TEMPLATE_SKILL_PATH = (
    ROOT / "plugins/flutter-mvvm-devkit/skills/flutter-mvvm-template"
)
RETIRED_TEST_SKILL_NAME = "flutter-mvvm-" + "test"
RETIRED_TEST_SKILL_PATH = ROOT / "project-skills" / RETIRED_TEST_SKILL_NAME
MARKETPLACE_RETIRED_TEST_SKILL_PATH = (
    MARKETPLACE_PROJECT_SKILLS_PATH / RETIRED_TEST_SKILL_NAME
)
CONTRACT_TEST_RANDOMIZATION_SEED = 2
PROJECT_SKILLS = (
    "code-quality",
    "feature-code-map",
    "flutter-mvvm-api-dev",
    "flutter-mvvm-feature-dev",
    "flutter-mvvm-inspector",
    "flutter-mvvm-mock-api-dev",
    "flutter-mvvm-pm-ui",
)
ALL_SKILL_NAMES = ("flutter-mvvm-template", *PROJECT_SKILLS)
CROSS_SKILL_ROUTING_PHRASES = (
    "对应开发 skill",
    "使用该项目内的局部 skills",
    "交由开发处理",
    "交由正式功能开发处理",
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
    "_replaced" + "Container",
    "replace" + "ForTesting",
    "AppContainer." + "restore",
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
    def test_api_dev_recommends_json_serializable_and_matches_marketplace_source(
        self,
    ) -> None:
        skill_text = searchable_text(API_DEV_SKILL_PATH)

        self.assertIn("推荐使用 `json_serializable`", skill_text)
        self.assertIn(
            "dart run build_runner build`，再格式化",
            skill_text,
        )
        self.assertNotIn("JSON model 必须使用", skill_text)
        self.assertNotIn("所有正式 request/response model 都使用", skill_text)
        self.assertNotIn("先用普通 Dart model 和手写", skill_text)
        self.assertEqual(
            directory_snapshot(API_DEV_SKILL_PATH),
            directory_snapshot(MARKETPLACE_API_DEV_SKILL_PATH),
        )

    def test_pm_ui_does_not_prescribe_dart_define_arguments(self) -> None:
        markdown = "\n".join(
            path.read_text(encoding="utf-8")
            for path in sorted(PM_UI_SKILL_PATH.rglob("*.md"))
        )
        dart_define_arguments = set(
            re.findall(r"--dart-define=[A-Za-z0-9_.-]+=[A-Za-z0-9_.-]+", markdown)
        )

        self.assertEqual(dart_define_arguments, set())
        self.assertIn("不得新增或修改任何 Dart define", markdown)

    def test_marketplace_pm_ui_skill_matches_source(self) -> None:
        self.assertEqual(
            directory_snapshot(PM_UI_SKILL_PATH),
            directory_snapshot(MARKETPLACE_PM_UI_SKILL_PATH),
        )

    def test_code_map_skill_is_concise_and_matches_marketplace_source(self) -> None:
        skill = (CODE_MAP_SKILL_PATH / "SKILL.md").read_text(encoding="utf-8")

        self.assertIn("docs/FEATURE_CODE_MAP.md", skill)
        self.assertIn("| 功能/别名 | 代码入口 | 检索锚点 |", skill)
        self.assertIn("不使用绝对路径、Markdown 文件链接或行号", skill)
        self.assertEqual(
            directory_snapshot(CODE_MAP_SKILL_PATH),
            directory_snapshot(MARKETPLACE_CODE_MAP_SKILL_PATH),
        )

    def test_code_quality_skill_is_language_agnostic_and_matches_marketplace_source(
        self,
    ) -> None:
        skill = (CODE_QUALITY_SKILL_PATH / "SKILL.md").read_text(encoding="utf-8")

        self.assertIn("任意编程语言", skill)
        self.assertIn("可读性作为有效方案之间的首要选择标准", skill)
        self.assertIn("适配当前项目", skill)
        self.assertIn("避免过度设计", skill)
        self.assertIn("不强制跨语言的函数行数", skill)
        self.assertNotIn("Flutter", skill)
        self.assertEqual(
            directory_snapshot(CODE_QUALITY_SKILL_PATH),
            directory_snapshot(MARKETPLACE_CODE_QUALITY_SKILL_PATH),
        )

    def test_retired_testing_skill_is_absent(self) -> None:
        self.assertFalse(RETIRED_TEST_SKILL_PATH.exists())
        self.assertFalse(MARKETPLACE_RETIRED_TEST_SKILL_PATH.exists())
        self.assertNotIn(
            RETIRED_TEST_SKILL_NAME,
            (ROOT / "README.md").read_text(encoding="utf-8"),
        )
        for skill_name in PROJECT_SKILLS:
            self.assertNotIn(
                RETIRED_TEST_SKILL_NAME,
                searchable_text(ROOT / "project-skills" / skill_name),
            )

    def test_development_skills_own_testing_completion_gates(self) -> None:
        direct_coverage_gate = (
            "先检查已有测试是否直接断言受影响的输入、动作、状态、输出或 contract",
            "仅执行到相关代码不算直接覆盖",
            "覆盖充分时复跑并记录依据",
            "覆盖不足时才新增或更新最小测试",
        )
        for skill_path in (
            FEATURE_DEV_SKILL_PATH,
            API_DEV_SKILL_PATH,
            MOCK_API_DEV_SKILL_PATH,
            PM_UI_SKILL_PATH,
        ):
            skill = (skill_path / "SKILL.md").read_text(encoding="utf-8")
            for guidance in direct_coverage_gate:
                self.assertIn(guidance, skill)

        development_gates = {
            FEATURE_DEV_SKILL_PATH: (
                "纯展示改动不新增或修改测试",
                "混合改动只覆盖行为部分",
            ),
            API_DEV_SKILL_PATH: (
                "API contract、model 解析、错误映射、Repository、ViewModel 和 wiring 全部属于非视觉改动",
            ),
            MOCK_API_DEV_SKILL_PATH: (
                "domain contract、mock 返回、非 mock fail-fast、wiring 和调用方全部属于非视觉改动",
                "不通过测试固化未确认的真实 URL",
            ),
            PM_UI_SKILL_PATH: (
                "纯展示、静态 fixture 和静态文案改动不新增或修改测试",
                "混合改动只覆盖行为部分",
            ),
            INSPECTOR_SKILL_PATH: (
                "纯展示修改不新增或修改测试",
                "涉及状态、callback、校验、交互、数据、API、导航、弹层结果或异步行为，停止本工作流并报告超出当前范围",
            ),
        }
        for skill_path, expected_guidance in development_gates.items():
            skill = (skill_path / "SKILL.md").read_text(encoding="utf-8")
            for guidance in expected_guidance:
                self.assertIn(guidance, skill)

        detailed_test_guidance = (
            "`addTearDown`",
            "`pumpAndSettle()`",
            "`testWidgets`",
            "--test-randomize-ordering-seed",
            "flutter test <scope> --coverage",
        )
        for skill_name in PROJECT_SKILLS:
            markdown = "\n".join(
                path.read_text(encoding="utf-8")
                for path in sorted((ROOT / "project-skills" / skill_name).rglob("*.md"))
            )
            for guidance in detailed_test_guidance:
                self.assertNotIn(guidance, markdown)

        for skill_path in (
            FEATURE_DEV_SKILL_PATH,
            API_DEV_SKILL_PATH,
            MOCK_API_DEV_SKILL_PATH,
            PM_UI_SKILL_PATH,
            INSPECTOR_SKILL_PATH,
        ):
            skill = (skill_path / "SKILL.md").read_text(encoding="utf-8")
            self.assertNotIn("或新增和修改测试", skill)
            self.assertNotIn("不在本工作流中新增或修改测试", skill)

        code_quality = searchable_text(CODE_QUALITY_SKILL_PATH)
        self.assertIn("遵循项目已有验证要求", code_quality)

    def test_skills_do_not_reference_other_skills(self) -> None:
        skill_paths = {
            "flutter-mvvm-template": ROOT / "skills/flutter-mvvm-template",
            **{
                skill_name: ROOT / "project-skills" / skill_name
                for skill_name in PROJECT_SKILLS
            },
        }

        for skill_name, skill_path in skill_paths.items():
            skill_text = searchable_text(skill_path)
            for other_skill_name in ALL_SKILL_NAMES:
                if other_skill_name == skill_name:
                    continue
                self.assertNotIn(
                    other_skill_name,
                    skill_text,
                    f"{skill_name} references {other_skill_name}",
                )
            for routing_phrase in CROSS_SKILL_ROUTING_PHRASES:
                self.assertNotIn(
                    routing_phrase,
                    skill_text,
                    f"{skill_name} contains cross-skill routing",
                )

    def test_all_marketplace_project_skills_match_source(self) -> None:
        canonical_skill_names = tuple(
            path.name
            for path in sorted((ROOT / "project-skills").iterdir())
            if path.is_dir()
        )
        marketplace_skill_names = tuple(
            path.name
            for path in sorted(MARKETPLACE_PROJECT_SKILLS_PATH.iterdir())
            if path.is_dir()
        )
        self.assertEqual(canonical_skill_names, PROJECT_SKILLS)
        self.assertEqual(marketplace_skill_names, PROJECT_SKILLS)
        for skill_name in PROJECT_SKILLS:
            self.assertEqual(
                directory_snapshot(ROOT / "project-skills" / skill_name),
                directory_snapshot(MARKETPLACE_PROJECT_SKILLS_PATH / skill_name),
            )

    def test_marketplace_template_skill_matches_source(self) -> None:
        self.assertEqual(
            directory_snapshot(ROOT / "skills/flutter-mvvm-template"),
            directory_snapshot(MARKETPLACE_TEMPLATE_SKILL_PATH),
        )

    def test_copy_project_skills_installs_all_managed_skills(self) -> None:
        with tempfile.TemporaryDirectory(prefix="flutter-mvvm-project-skills-") as temporary:
            target = Path(temporary)

            managed_skills = generator.copy_project_skills(target)

            self.assertEqual(tuple(managed_skills), PROJECT_SKILLS)
            for skill_name in PROJECT_SKILLS:
                self.assertEqual(
                    directory_snapshot(ROOT / "project-skills" / skill_name),
                    directory_snapshot(target / ".codex/skills" / skill_name),
                )

    def test_overlay_uses_app_container_architecture(self) -> None:
        lib = OVERLAY_PATH / "lib"

        self.assertTrue((lib / "app_container.dart").is_file())
        self.assertFalse((lib / "services" / LEGACY_APP_SERVICES_FILE).exists())
        for removed in REMOVED_ARCHITECTURE_REFERENCES:
            self.assertNotIn(removed, searchable_text(OVERLAY_PATH))

    def test_overlay_uses_json_serializable(self) -> None:
        pubspec_patch = (OVERLAY_PATH / "template_pubspec_patch.yaml").read_text(
            encoding="utf-8"
        )
        user_model = (
            OVERLAY_PATH / "lib/models/user/user_profile.dart"
        ).read_text(encoding="utf-8")
        generated_model = (
            OVERLAY_PATH / "lib/models/user/user_profile.g.dart"
        ).read_text(encoding="utf-8")

        for dependency in ("json_annotation", "json_serializable", "build_runner"):
            self.assertIn(dependency, pubspec_patch)
        self.assertIn("@JsonSerializable()", user_model)
        self.assertIn("part 'user_profile.g.dart';", user_model)
        self.assertIn("_$UserProfileFromJson", generated_model)
        self.assertIn("_$UserProfileToJson", generated_model)

    def test_handwritten_template_dart_files_have_chinese_docs(self) -> None:
        lib = OVERLAY_PATH / "lib"
        handwritten_files = [
            path
            for path in sorted(lib.rglob("*.dart"))
            if not path.name.endswith(".g.dart")
        ]

        self.assertGreater(len(handwritten_files), 0)
        for path in handwritten_files:
            source = path.read_text(encoding="utf-8")
            self.assertRegex(
                source,
                r"(?m)^\s*///.*[\u4e00-\u9fff]",
                f"missing Chinese DartDoc: {path.relative_to(OVERLAY_PATH)}",
            )

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
                    [
                        "dart",
                        "run",
                        "build_runner",
                        "build",
                    ],
                    cwd=target,
                    allow_failure=True,
                ),
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
                    "run",
                    "build_runner",
                    "build",
                ],
                cwd=project,
            )
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
            self.run_command(
                [
                    "flutter",
                    "test",
                    f"--test-randomize-ordering-seed={CONTRACT_TEST_RANDOMIZATION_SEED}",
                ],
                cwd=project,
            )

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
