#!/usr/bin/env bash
set -euo pipefail

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bin_dir="${1:-$HOME/.local/bin}"

mkdir -p "$bin_dir"
ln -sf "$skill_dir/scripts/flutter_mvvm.py" "$bin_dir/flutter-mvvm"
chmod +x "$skill_dir/scripts/flutter_mvvm.py"

echo "Installed flutter-mvvm to $bin_dir/flutter-mvvm"
echo "Make sure $bin_dir is on your PATH."
