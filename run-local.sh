#!/bin/zsh

set -euo pipefail

rtk swift build -c debug

app_dir=".build/VistaRest.app"
contents_dir="$app_dir/Contents"
mkdir -p "$contents_dir/MacOS"

build_dir="$(rtk swift build -c debug --show-bin-path)"
cp "$build_dir/VistaRest" "$contents_dir/MacOS/VistaRest"
cp Info.plist "$contents_dir/Info.plist"
rtk ./make-app-icon.sh "$contents_dir"

open "$app_dir"
