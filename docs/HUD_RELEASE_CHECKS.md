# HUD release checks

Do not treat a successful build or successful Sparkle install as proof that the HUD works.

Before installing or packaging a custom build, run:

```sh
bash .github/scripts/verify_custom_app_identity.sh "path/to/candidate.app" "path/to/previous-trusted.app"
```

For subsequent local builds, use the signed build entry point; it runs this gate
automatically and fails the build workflow if the gate fails:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  bash .github/scripts/build_custom_signed_app.sh "path/to/previous-trusted.app" "/tmp/boringnotch-sports-derived"
```

This fails on invalid/ad-hoc signing, a changed bundle identity or team, a changed
Sparkle public key, or a changed app/helper designated signing requirement. Keep
the installed path stable. Switching from Apple Development to Developer ID
requires a deliberate permission-migration plan; do not silently switch identities.

With HUD replacement enabled, identify the installed app's running PID and run:

```sh
swift tests/HUDRuntimeSmoke.swift RUNNING_APP_PID
```

Run this after a cold launch, the Restart HUD control, closing Settings, and a
real Sparkle update/relaunch. Check an actual volume/brightness key visually too.
Verify that the original HUD preference, Dock visibility, theme, and layout remain
unchanged. CI cannot grant macOS permission or perform the live media-key test;
perform these checks on the signed installed app before claiming release success.

Recovery uses bounded retries at launch/activation/wake, not a permanent watchdog.
The status checks the actual enabled event tap and its run-loop source. An existing
permission denial must still be handled by the user in macOS; never reset TCC or
grant access automatically. Do not overwrite a published release archive with a
new build; release a new version for subsequent corrections.
