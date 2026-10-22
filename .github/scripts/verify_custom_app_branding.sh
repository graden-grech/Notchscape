#!/bin/bash
# Xcode may reuse generated plist output during an incremental build. Signing
# trust alone cannot establish that the artifact contains the requested branding.
set -euo pipefail
candidate="${1:?Usage: verify_custom_app_branding.sh candidate.app source-Info.plist}"
source_info="${2:?Usage: verify_custom_app_branding.sh candidate.app source-Info.plist}"
built_info="$candidate/Contents/Info.plist"
for key in CFBundleName CFBundleDisplayName; do
    expected="$(/usr/libexec/PlistBuddy -c "Print :$key" "$source_info")"
    actual="$(/usr/libexec/PlistBuddy -c "Print :$key" "$built_info")"
    if [[ -z "$expected" || "$actual" != "$expected" ]]; then
        printf 'FAIL: built %s does not match the requested source branding; rebuild before install.\n' "$key" >&2
        exit 1
    fi
done
printf 'PASS: built app name and display name match source branding\n'
