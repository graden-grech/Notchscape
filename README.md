<p align="center">
  <img src="boringNotch/Assets.xcassets/AppIcon.appiconset/notch-stage-icon2%2010.png" alt="Notchscape icon" width="128" />
</p>

# Notchscape

Your Mac, together. Music, calendar, weather, wallpapers and useful local tools
in one native macOS workspace, at the top of your display.

Maintained by [Graden Grech](https://github.com/graden-grech).

[![Build and test](https://github.com/graden-grech/Notchscape/actions/workflows/cicd.yml/badge.svg)](https://github.com/graden-grech/Notchscape/actions/workflows/cicd.yml)
[![Security checks](https://github.com/graden-grech/Notchscape/actions/workflows/codeql.yml/badge.svg)](https://github.com/graden-grech/Notchscape/actions/workflows/codeql.yml)

## One workspace

- A configurable notch or floating island, with per-display visibility.
- Music controls, calendar and reminders, location-aware weather, and a file shelf.
- Local Codex and Claude Code activity, with distinct completion and usage-limit states.
- Optional volume and brightness HUDs, battery controls, and system monitoring.
- Seasonal themes, matching icons, custom accent colors and Home layout controls.
- 328 wallpapers adapted from MacScapes and credited sources, with theme matching,
  favorites, previews, display selection and optional rotation.
- Eight temporary workspace Modes, with one-click End/Restore and a manual-end
  Presentation privacy mode. [Mode behavior and limits](docs/WORKSPACE_MODES.md).
- Local Quick Notes, optional Apple Notes sync, clipboard history and text recognition.
- Searchable Settings and a consistent, native control language.

The wallpaper and newer tools work is currently in the source tree, not yet in
the public downloadable app. The latest public release is **2.8.4 (287)**,
published before the Notchscape rebrand. Accounts remain disabled in public
builds; no app account is required.

## Download and updates

[Public releases](https://github.com/graden-grech/Notchscape/releases)
include version-specific notes and known testing limits. The current public
binary requires Apple silicon and macOS 14 or later. Native Liquid Glass is
available on macOS 26 or later; earlier systems use lighter standard materials.

The app is development-signed with its existing identity, **not notarized**.
Review the release notes before installing. If macOS blocks a download you
trust, review it in System Settings → Privacy & Security. This project does not
recommend disabling Gatekeeper or globally changing system security settings.

Automatic updates continue through this repository's signed Sparkle feed. The
repository is now **graden-grech/Notchscape**; legacy repository, feed and release
download paths still resolve for existing installations. Do not reuse the old
repository name or remove compatibility downloads. The app's internal identity,
signing trust and installed path remain stable to preserve settings and HUD
permissions. A source push is not an app release; signed archives and the update
feed are published separately. See the [update destination and rename policy](docs/UPDATES_AND_REPOSITORY_RENAME.md).

Existing standalone MacScapes users need a one-time installation of a released
combined app, not a cross-bundle automatic replacement. See the
[migration and updater policy](docs/MACSCAPES_MIGRATION.md).

## Build and verify

Open `boringNotch.xcodeproj` in Xcode 26 or later. The project and executable
retain their compatibility names; the user-facing app name is Notchscape.
For trusted local builds, follow [AGENTS.md](AGENTS.md) and the
[HUD release checklist](docs/HUD_RELEASE_CHECKS.md). Do not install an unsigned
CI build over a permission-approved app.

```sh
git clone https://github.com/graden-grech/Notchscape.git
cd Notchscape
open boringNotch.xcodeproj
python3 -m unittest discover -s .github/scripts/tests -q
```

Fresh-device onboarding, full VoiceOver coverage, external-display/DisplayLink
behavior and all supported macOS versions require further device testing. The
experimental lock-screen dropdown uses inherited private SkyLight integration.
Commercial distribution also needs review of weather/artwork provider rights.

## Help and contributions

[Report a bug or suggest an improvement](https://github.com/graden-grech/Notchscape/issues).
See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution and verification process.
Optional inherited publishing jobs remain opt-in; see
[GitHub automation setup](docs/custom-fork-ci.md).

## License and acknowledgments

Notchscape is an independently maintained derivative of the GPL-licensed Boring
Notch project. The new product name does not remove original authors' rights or
license obligations, and does not imply their endorsement. See
[attribution and preserved credits](docs/ATTRIBUTION.md), the
[GNU GPL v3 license](LICENSE), and [third-party licenses](THIRD_PARTY_LICENSES).
