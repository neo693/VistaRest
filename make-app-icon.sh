#!/bin/zsh

set -euo pipefail

project_dir="${0:A:h}"
contents_dir="${1:?Usage: ./make-app-icon.sh <app-contents-dir>}"
work_dir="$(rtk mktemp -d "$project_dir/.build/VistaRest-icon-work.XXXXXX")"
iconset_dir="$work_dir/AppIcon.iconset"
cropped_path="$work_dir/cropped.png"
scaled_path="$work_dir/scaled.png"
source_path="$work_dir/padded.png"

trap 'rtk rm -rf "$work_dir"' EXIT

rtk mkdir -p "$contents_dir/Resources"
rtk cp "$project_dir/logo.png" "$contents_dir/Resources/logo.png"
rtk mkdir -p "$iconset_dir"
# macOS 会按画布尺寸展示图标；保留约 20% 的透明安全边距，避免比系统图标显得大一圈。
rtk sips -c 1055 1055 "$project_dir/logo.png" --out "$cropped_path" >/dev/null
rtk sips -z 819 819 "$cropped_path" --out "$scaled_path" >/dev/null
rtk sips -p 1024 1024 "$scaled_path" --out "$source_path" >/dev/null

rtk sips -z 16 16 "$source_path" --out "$iconset_dir/icon_16x16.png" >/dev/null
rtk sips -z 32 32 "$source_path" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
rtk sips -z 128 128 "$source_path" --out "$iconset_dir/icon_128x128.png" >/dev/null
rtk sips -z 256 256 "$source_path" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null

rtk iconutil -c icns "$iconset_dir" -o "$contents_dir/Resources/AppIcon.icns"
