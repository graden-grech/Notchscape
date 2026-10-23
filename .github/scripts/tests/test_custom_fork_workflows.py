"""Keep optional upstream services from failing in an unconfigured custom fork."""

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]


class CustomForkWorkflowTests(unittest.TestCase):
    def test_ai_chat_title_checks_run_in_ci(self):
        workflow = (ROOT / ".github/workflows/cicd.yml").read_text()
        self.assertIn("boringNotch/models/AgentChatTitle.swift tests/AgentChatTitleTests.swift", workflow)
        self.assertIn('"$RUNNER_TEMP/agent-chat-title-tests"', workflow)

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

    def test_native_sdk_build_retains_intel_runner_and_feature_policy_checks(self):
        workflow = (ROOT / ".github/workflows/cicd.yml").read_text()
        self.assertIn("runs-on: macos-26-intel", workflow)
        self.assertIn("          - ^26", workflow)
        self.assertIn("          - boringNotch", workflow)
        self.assertIn("tests/CustomizationPolicyTests.swift", workflow)
        self.assertIn("tests/ProductivityPolicyTests.swift", workflow)
        self.assertIn("tests/NotchUtilitiesPolicyTests.swift", workflow)
        self.assertIn("boringNotch/models/WorkspaceModeModels.swift", workflow)
        self.assertIn("tests/WorkspaceModePolicyTests.swift", workflow)
        self.assertIn('"$RUNNER_TEMP/workspace-mode-tests"', workflow)
        self.assertIn("tests/AccountSettingsPolicyTests.swift", workflow)


if __name__ == "__main__":
    unittest.main()
