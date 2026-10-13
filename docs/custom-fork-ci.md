# Custom fork automation

Normal macOS builds and CodeQL security checks remain enabled on pushes.
Optional upstream publishing jobs are not part of the custom fork's local,
signed-release process:

- **Nightly Branch Builds** only runs for the upstream repository or after
  `ENABLE_NIGHTLY_BUILDS=true` is explicitly configured. This fork has no `dev`
  branch or hosted signing secrets. Before enabling it, adapt the repository
  links and release-app configuration, create the intended branch, and configure
  signing, Sparkle, and release credentials. Do not enable it just to clear a
  skipped status.
- **Deploy static content to Pages** only runs for upstream or after
  `ENABLE_GITHUB_PAGES=true` is configured. Enable a GitHub Actions Pages site
  first. The custom appcast is served from raw GitHub and does not need Pages.
- The empty **Crowdin Sync** workflow was removed because a job with no steps
  is invalid. Translation files remain unchanged. Add a complete workflow if a
  translation service is configured later.

A source push does not create a downloadable app release or advance Sparkle's
update feed. Those require a separately versioned, signed, verified archive.
