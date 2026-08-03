#!/bin/zsh

set -euo pipefail

app_version="0.1.0"
architecture="$(rtk uname -m)"
app_dir=".build/VistaRest.app"
contents_dir="$app_dir/Contents"
dist_dir="dist"
dmg_path="$dist_dir/VistaRest-$app_version-macOS-$architecture.dmg"
zip_path="$dist_dir/VistaRest-$app_version-macOS-$architecture.zip"

rtk swift build -c release
build_dir="$(rtk swift build -c release --show-bin-path)"

rtk mkdir -p "$contents_dir/MacOS" "$dist_dir"
rtk cp "$build_dir/VistaRest" "$contents_dir/MacOS/VistaRest"
rtk cp Info.plist "$contents_dir/Info.plist"
rtk chmod +x "$contents_dir/MacOS/VistaRest"

# 本地 ad-hoc 签名足够用于这台 Mac 的安装测试，不代表 App Store 发布签名。
rtk codesign --force --deep --sign - "$app_dir"
rtk codesign --verify --deep --strict "$app_dir"

rtk rm -f "$dmg_path" "$zip_path"
rtk hdiutil create \
    -volname "远眺" \
    -srcfolder "$app_dir" \
    -ov \
    -format UDZO \
    "$dmg_path"
rtk ditto -c -k --keepParent "$app_dir" "$zip_path"

rtk shasum -a 256 "$dmg_path" "$zip_path"
