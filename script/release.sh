#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
version="${1:-}"
identity="${SIGNING_IDENTITY:-}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "用法: SIGNING_IDENTITY=... APPLE_ID=... APPLE_ID_PASSWORD=... TEAM_ID=... $0 X.Y.Z" >&2
    exit 2
fi
for variable_name in SIGNING_IDENTITY APPLE_ID APPLE_ID_PASSWORD TEAM_ID; do
    if [[ -z "${!variable_name:-}" ]]; then
        echo "缺少发行参数: $variable_name" >&2
        exit 1
    fi
done

dist="$project_root/dist"
app="$dist/CodexModelManager.app"
dmg="$dist/Codex-Model-Manager.dmg"
checksum="$dmg.sha256"
staging="$(/usr/bin/mktemp -d /tmp/codex-model-manager-release.XXXXXX)"
trap '/bin/rm -rf -- "$staging"' EXIT

"$project_root/script/build_app.sh" \
    --configuration release \
    --output "$app" \
    --identity "$identity" \
    --version "$version" \
    --build-number "${version//./}" \
    --universal

details="$(/usr/bin/codesign -dvvv "$app" 2>&1)"
/usr/bin/grep -q '^Authority=Developer ID Application:' <<<"$details"
/usr/bin/grep -q '^TeamIdentifier='"$TEAM_ID"'$' <<<"$details"
/usr/bin/grep -q 'flags=.*runtime' <<<"$details"
/usr/bin/file "$app/Contents/MacOS/CodexModelManager" | /usr/bin/grep -q 'universal binary'
/usr/bin/file "$app/Contents/Helpers/CodexModelSync" | /usr/bin/grep -q 'universal binary'

/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app" "$staging/app.zip"
/usr/bin/xcrun notarytool submit "$staging/app.zip" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_ID_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait \
    --timeout 30m \
    --output-format json > "$dist/app-notarization.json"
test "$(/usr/bin/plutil -extract status raw -o - "$dist/app-notarization.json")" = "Accepted"
/usr/bin/xcrun stapler staple "$app"
/usr/bin/xcrun stapler validate "$app"
/usr/sbin/spctl --assess --type execute --verbose=4 "$app"
/bin/rm -f "$staging/app.zip"

/usr/bin/ditto "$app" "$staging/CodexModelManager.app"
/bin/ln -s /Applications "$staging/Applications"
/bin/rm -f "$dmg" "$checksum"
/usr/bin/hdiutil create \
    -volname "Codex Model Manager" \
    -srcfolder "$staging" \
    -ov \
    -format UDZO \
    "$dmg"
/usr/bin/codesign --force --timestamp --sign "$identity" "$dmg"
/usr/bin/xcrun notarytool submit "$dmg" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_ID_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait \
    --timeout 30m \
    --output-format json > "$dist/dmg-notarization.json"
test "$(/usr/bin/plutil -extract status raw -o - "$dist/dmg-notarization.json")" = "Accepted"
/usr/bin/xcrun stapler staple "$dmg"
/usr/bin/xcrun stapler validate "$dmg"
/usr/sbin/spctl --assess --type open --context context:primary-signature --verbose=4 "$dmg"

(
    cd "$dist"
    /usr/bin/shasum -a 256 "$(/usr/bin/basename "$dmg")" > "$(/usr/bin/basename "$checksum")"
)
echo "$dmg"
echo "$checksum"
