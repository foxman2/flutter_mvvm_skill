from __future__ import annotations

import importlib.util
from pathlib import Path
import re
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = ROOT / "scripts" / "sync_marketplace_plugin.py"
spec = importlib.util.spec_from_file_location("sync_marketplace_plugin", SCRIPT_PATH)
assert spec is not None and spec.loader is not None
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class SharedArchitectureReferenceTests(unittest.TestCase):
    def test_source_update_replaces_shared_reference_in_marketplace(self) -> None:
        """Publishing keeps one current reference and removes obsolete bundle files."""
        with tempfile.TemporaryDirectory(prefix="mvvm-shared-reference-") as temporary:
            root = Path(temporary)
            relative = Path("project-skills/shared-references/architecture-responsibilities.md")
            source = root / relative
            source.parent.mkdir(parents=True)
            source.write_text("First contract\n", encoding="utf-8")
            marketplace = root / "plugins" / "example"
            sync.copy_plugin_source(root, marketplace)

            obsolete = marketplace / "project-skills/example/references/architecture-responsibilities.md"
            obsolete.parent.mkdir(parents=True)
            obsolete.write_text("Old copy\n", encoding="utf-8")
            source.write_text("Revised contract\n", encoding="utf-8")
            sync.copy_plugin_source(root, marketplace)

            self.assertEqual((marketplace / relative).read_bytes(), source.read_bytes())
            self.assertEqual(list(marketplace.rglob(source.name)), [marketplace / relative])

    def test_marketplace_shared_reference_and_consumer_links(self) -> None:
        """The published package must include the shared target of every consumer."""
        source = ROOT / "project-skills"
        marketplace = ROOT / "plugins/flutter-mvvm-devkit/project-skills"
        relative = Path("shared-references/architecture-responsibilities.md")
        self.assertEqual((source / relative).read_bytes(), (marketplace / relative).read_bytes())
        self.assertEqual(list(marketplace.rglob(relative.name)), [marketplace / relative])
        for name in (
            "flutter-mvvm-api-dev", "flutter-mvvm-feature-dev",
            "flutter-mvvm-mock-api-dev", "flutter-mvvm-pm-ui",
        ):
            skill = marketplace / name
            for document in skill.rglob("*.md"):
                for link in re.findall(r"\]\(([^)]+\.md)\)", document.read_text(encoding="utf-8")):
                    target = (document.parent / link).resolve()
                    self.assertTrue(target.is_relative_to(marketplace.resolve()), link)
                    self.assertTrue(target.is_file(), link)


if __name__ == "__main__":
    unittest.main()
