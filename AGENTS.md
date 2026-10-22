# Custom fork build and release rules

- Preserve user preferences, app identity, and the installed app path. Do not reset
  macOS permissions or modify global Dock settings as part of a build or update.
- Use `.github/scripts/build_custom_signed_app.sh` for local install/release builds,
  with a previously trusted app as the identity baseline. Never install unsigned
  or ad-hoc CI products over the permission-approved app.
- Before packaging, run `.github/scripts/verify_custom_app_identity.sh`. A failed
  signing-identity or Sparkle-key comparison requires explicit migration planning,
  not disabling the gate.
- Follow `docs/HUD_RELEASE_CHECKS.md`. Check the enabled HUD event tap after a cold
  launch, Restart HUD, closing Settings, and a real update/relaunch. A successful
  compile or Sparkle installation alone is not a passed HUD regression test.
- Publish only to `personal` (`graden-grech/Notchscape`) with user authority.
  Never replace a published archive with a different build. Use a new version for
  post-release corrections and retain old update-feed items.
- Report release, updater, HUD, and CI outcomes separately. Clearly state any live
  hardware, permission, or update-path testing that remains unverified.
