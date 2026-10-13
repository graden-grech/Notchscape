"""Keep optional upstream services from failing in an unconfigured custom fork."""

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]


class CustomForkWorkflowTests(unittest.TestCase):
    def test_nightly_is_opt_in_for_forks(self):
        workflow = (ROOT / ".github/workflows/nightly.yml").read_text()
        prepare = workflow.split("  prepare:\n", 1)[1].split("  build:\n", 1)[0]
        self.assertIn("vars.ENABLE_NIGHTLY_BUILDS == 'true'", prepare)
        self.assertIn("github.repository == 'TheBoredTeam/boring.notch'", prepare)

    def test_website_deployment_is_opt_in_for_forks(self):
        workflow = (ROOT / ".github/workflows/static.yml").read_text()
        self.assertIn("vars.ENABLE_GITHUB_PAGES == 'true'", workflow)
        self.assertIn("github.repository == 'TheBoredTeam/boring.notch'", workflow)

    def test_incomplete_translation_workflow_is_not_registered(self):
        self.assertFalse((ROOT / ".github/workflows/crowdin.yml").exists())

    def test_app_build_and_security_checks_still_run_on_push(self):
        for name in ("cicd.yml", "codeql.yml"):
            workflow = (ROOT / ".github/workflows" / name).read_text()
            self.assertIn("  push:\n", workflow)
            self.assertNotIn("ENABLE_NIGHTLY_BUILDS", workflow)
            self.assertNotIn("ENABLE_GITHUB_PAGES", workflow)


if __name__ == "__main__":
    unittest.main()
