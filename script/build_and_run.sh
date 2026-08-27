#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
configuration="debug"
show_logs=0
telemetry=0
verify=0

for argument in "$@"; do
    case "$argument" in
        --debug)
            configuration="debug"
            ;;
        --logs)
            show_logs=1
            ;;
        --telemetry)
            telemetry=1
            ;;
        --verify)
            verify=1
            ;;
        *)
            echo "未知参数: $argument" >&2
            exit 2
            ;;
    esac
done

cd "$project_root"

/usr/bin/pkill -x CodexModelManager 2>/dev/null || true
/usr/bin/swift build -c "$configuration"

binary_dir="$(/usr/bin/swift build -c "$configuration" --show-bin-path)"
user_name="$(/usr/bin/id -un)"
user_home_dir="$(/usr/bin/dscl . -read "/Users/$user_name" NFSHomeDirectory | /usr/bin/awk '{print $2}')"
if [[ -z "$user_home_dir" || "$user_home_dir" != /* || "$user_home_dir" == "/" ]]; then
    echo "无法确认当前用户目录，停止安装。" >&2
    exit 1
fi
install_directory="$user_home_dir/Applications"
configuration_source="$project_root/Config/local.json"
configuration_directory="$user_home_dir/Library/Application Support/CodexModelManager"
configuration_path="$configuration_directory/config.json"
app_path="$install_directory/CodexModelManager.app"
contents_path="$app_path/Contents"
macos_path="$contents_path/MacOS"
resources_path="$contents_path/Resources"
plist_path="$contents_path/Info.plist"
icon_source="$project_root/Resources/AppIcon.png"

if [[ ! -f "$icon_source" ]]; then
    echo "缺少应用图标: $icon_source" >&2
    exit 1
fi

icon_width="$(/usr/bin/sips -g pixelWidth "$icon_source" | /usr/bin/awk '/pixelWidth/ { print $2 }')"
icon_height="$(/usr/bin/sips -g pixelHeight "$icon_source" | /usr/bin/awk '/pixelHeight/ { print $2 }')"
if [[ "$icon_width" != "1024" || "$icon_height" != "1024" ]]; then
    echo "应用图标必须是 1024 x 1024，当前为 ${icon_width} x ${icon_height}。" >&2
    exit 1
fi

if [[ -f "$configuration_source" ]]; then
    /bin/mkdir -p "$configuration_directory"
    /usr/bin/install -m 600 "$configuration_source" "$configuration_path"
elif [[ ! -f "$configuration_path" ]]; then
    echo "提示: 尚未配置本机模型目录，应用启动后会显示配置说明。" >&2
fi

/bin/mkdir -p "$install_directory"
/bin/rm -rf "$app_path"
/bin/mkdir -p "$macos_path" "$resources_path"
/usr/bin/ditto "$binary_dir/CodexModelManager" "$macos_path/CodexModelManager"

icon_work_directory="$(/usr/bin/mktemp -d /tmp/codex-model-manager-icon.XXXXXX)"
trap '/bin/rm -rf -- "$icon_work_directory"' EXIT
iconset_path="$icon_work_directory/AppIcon.iconset"
/bin/mkdir -p "$iconset_path"

create_icon_size() {
    local size="$1"
    local output="$2"
    /usr/bin/sips -z "$size" "$size" "$icon_source" --out "$iconset_path/$output" >/dev/null
}

create_icon_size 16 icon_16x16.png
create_icon_size 32 icon_16x16@2x.png
create_icon_size 32 icon_32x32.png
create_icon_size 64 icon_32x32@2x.png
create_icon_size 128 icon_128x128.png
create_icon_size 256 icon_128x128@2x.png
create_icon_size 256 icon_256x256.png
create_icon_size 512 icon_256x256@2x.png
create_icon_size 512 icon_512x512.png
create_icon_size 1024 icon_512x512@2x.png
/usr/bin/iconutil -c icns "$iconset_path" -o "$resources_path/AppIcon.icns"

/usr/bin/plutil -create xml1 "$plist_path"
/usr/bin/plutil -insert CFBundleDevelopmentRegion -string "zh_CN" "$plist_path"
/usr/bin/plutil -insert CFBundleDisplayName -string "Codex 模型管理器" "$plist_path"
/usr/bin/plutil -insert CFBundleExecutable -string "CodexModelManager" "$plist_path"
/usr/bin/plutil -insert CFBundleIconFile -string "AppIcon" "$plist_path"
/usr/bin/plutil -insert CFBundleIdentifier -string "com.onepersonlab.codex-model-manager" "$plist_path"
/usr/bin/plutil -insert CFBundleInfoDictionaryVersion -string "6.0" "$plist_path"
/usr/bin/plutil -insert CFBundleName -string "CodexModelManager" "$plist_path"
/usr/bin/plutil -insert CFBundlePackageType -string "APPL" "$plist_path"
/usr/bin/plutil -insert CFBundleShortVersionString -string "0.2.0" "$plist_path"
/usr/bin/plutil -insert CFBundleVersion -string "2" "$plist_path"
/usr/bin/plutil -insert LSMinimumSystemVersion -string "14.0" "$plist_path"
/usr/bin/plutil -insert NSHighResolutionCapable -bool true "$plist_path"

/usr/bin/xattr -cr "$app_path"
/usr/bin/codesign --force --sign - "$app_path"

if (( verify )); then
    /usr/bin/plutil -lint "$plist_path"
    /usr/bin/codesign --verify --deep --strict "$app_path"
fi

if (( telemetry )); then
    export OS_ACTIVITY_MODE=enable
fi

/usr/bin/open -n "$app_path"

if (( verify )); then
    launched=0
    for _ in {1..20}; do
        if /usr/bin/pgrep -x CodexModelManager >/dev/null; then
            launched=1
            break
        fi
        /bin/sleep 0.25
    done
    if (( ! launched )); then
        echo "应用未能在 5 秒内启动。" >&2
        exit 1
    fi
    echo "验证通过: $app_path"
fi

if (( show_logs )); then
    exec /usr/bin/log stream --style compact --predicate 'process == "CodexModelManager"'
fi
