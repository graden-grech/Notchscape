# Custom releases and updates

This fork publishes source and signed update archives at
`graden-grech/boringNotch-custom`.

The app checks this public Sparkle feed:

`https://raw.githubusercontent.com/graden-grech/boringNotch-custom/main/appcast.xml`

Update archives are signed with a dedicated Sparkle EdDSA key stored in the
local macOS Keychain under the account `boringNotch-custom`. The private key is
not committed to GitHub. `SUPublicEDKey` in `boringNotch/Info.plist` contains
only the matching public key.

For each future release:

1. Increase `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` for both the app
   and XPC helper targets.
2. Build the Release configuration with the same Apple signing identity.
3. Archive the signed app as `boringNotch-custom.zip`.
4. Run Sparkle's `generate_appcast` with `--account boringNotch-custom` and a
   download URL for the matching GitHub release tag.
5. Publish the tag and ZIP, then commit and push the updated `appcast.xml`.
6. Confirm the raw appcast and release asset are publicly reachable before
   announcing the update.

The `origin` Git remote remains the official TheBoredTeam repository so future
upstream changes can be reviewed and merged. The `personal` remote is the
public custom repository used for releases.
