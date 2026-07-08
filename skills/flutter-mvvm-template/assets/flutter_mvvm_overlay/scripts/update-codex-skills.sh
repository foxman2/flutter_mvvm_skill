#!/usr/bin/env bash
set -euo pipefail

REPO="foxman2/flutter_mvvm_skill"
ASSET_NAME="flutter-mvvm-skills.tar.gz"
VERSION=""
ARCHIVE=""

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/update-codex-skills.sh [--version v0.1.3] [--archive path/to/flutter-mvvm-skills.tar.gz]

Options:
  --version VERSION   Install a specific GitHub Release tag, for example v0.1.3.
  --archive PATH      Install from a local flutter-mvvm-skills.tar.gz archive.
  --repo OWNER/REPO   Override the GitHub repository. Defaults to foxman2/flutter_mvvm_skill.
  -h, --help          Show this help.

Set GITHUB_TOKEN to download release assets from a private repository.
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      [ "$#" -ge 2 ] || fail "--version requires a value"
      VERSION="$2"
      shift 2
      ;;
    --archive)
      [ "$#" -ge 2 ] || fail "--archive requires a value"
      ARCHIVE="$2"
      shift 2
      ;;
    --repo)
      [ "$#" -ge 2 ] || fail "--repo requires a value"
      REPO="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

if [ -n "$VERSION" ] && [ -n "$ARCHIVE" ]; then
  fail "use either --version or --archive, not both"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "python3 is required"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

absolute_path() {
  local path="$1"
  local dir
  dir="$(cd "$(dirname "$path")" && pwd)"
  printf "%s/%s\n" "$dir" "$(basename "$path")"
}

download_public_asset() {
  local destination="$1"
  local url

  if [ -n "$VERSION" ]; then
    url="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET_NAME}"
  else
    url="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"
  fi

  curl -fL "$url" -o "$destination"
}

download_api_asset() {
  local destination="$1"
  local release_json="$TMP_DIR/release.json"
  local api_url

  if [ -n "$VERSION" ]; then
    api_url="https://api.github.com/repos/${REPO}/releases/tags/${VERSION}"
  else
    api_url="https://api.github.com/repos/${REPO}/releases/latest"
  fi

  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$api_url" \
    -o "$release_json"

  local asset_id
  asset_id="$(python3 - "$release_json" "$ASSET_NAME" <<'PY'
import json
import sys

release_file, asset_name = sys.argv[1:3]
with open(release_file, encoding="utf-8") as handle:
    release = json.load(handle)

for asset in release.get("assets", []):
    if asset.get("name") == asset_name:
        print(asset["id"])
        break
else:
    print(f"release asset not found: {asset_name}", file=sys.stderr)
    sys.exit(1)
PY
)"

  curl -fL \
    -H "Accept: application/octet-stream" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}" \
    -o "$destination"
}

download_asset() {
  local destination="$1"

  if download_public_asset "$destination"; then
    return
  fi

  if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "Public release download failed; retrying through the GitHub API with GITHUB_TOKEN." >&2
    download_api_asset "$destination"
    return
  fi

  fail "could not download ${ASSET_NAME}; set GITHUB_TOKEN for private releases"
}

archive_path="$TMP_DIR/$ASSET_NAME"
if [ -n "$ARCHIVE" ]; then
  archive_path="$(absolute_path "$ARCHIVE")"
  [ -f "$archive_path" ] || fail "archive not found: $archive_path"
else
  download_asset "$archive_path"
fi

if tar -tzf "$archive_path" | grep -E '(^/|(^|/)\.\.(/|$))' >/dev/null; then
  fail "archive contains unsafe paths"
fi

EXTRACT_DIR="$TMP_DIR/extract"
mkdir -p "$EXTRACT_DIR"
tar -xzf "$archive_path" -C "$EXTRACT_DIR"

INCOMING_MANIFEST="$EXTRACT_DIR/.codex/flutter-mvvm-skills.json"
INCOMING_SKILLS_DIR="$EXTRACT_DIR/.codex/skills"
[ -d "$INCOMING_SKILLS_DIR" ] || fail "archive does not contain .codex/skills"

incoming_skills="$TMP_DIR/incoming-skills.txt"
current_skills="$TMP_DIR/current-skills.txt"

python3 - "$INCOMING_MANIFEST" "$INCOMING_SKILLS_DIR" > "$incoming_skills" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
skills_dir = Path(sys.argv[2])

names = []
if manifest_path.is_file():
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    names = list(data.get("managedSkills") or [])

if not names:
    names = sorted(path.name for path in skills_dir.iterdir() if (path / "SKILL.md").is_file())

for name in names:
    print(name)
PY

[ -s "$incoming_skills" ] || fail "archive does not declare any managed skills"

CURRENT_MANIFEST="$PROJECT_ROOT/.codex/flutter-mvvm-skills.json"
python3 - "$CURRENT_MANIFEST" "$incoming_skills" > "$current_skills" <<'PY'
import json
import sys
from pathlib import Path

current_manifest = Path(sys.argv[1])
incoming_file = Path(sys.argv[2])

names = []
if current_manifest.is_file():
    data = json.loads(current_manifest.read_text(encoding="utf-8"))
    names = list(data.get("managedSkills") or [])

if not names:
    names = [line.strip() for line in incoming_file.read_text(encoding="utf-8").splitlines() if line.strip()]

for name in names:
    print(name)
PY

mkdir -p "$PROJECT_ROOT/.codex/skills"

while IFS= read -r skill_name; do
  [ -n "$skill_name" ] || continue
  rm -rf "$PROJECT_ROOT/.codex/skills/$skill_name"
done < "$current_skills"

while IFS= read -r skill_name; do
  [ -n "$skill_name" ] || continue
  source_dir="$INCOMING_SKILLS_DIR/$skill_name"
  [ -d "$source_dir" ] || fail "managed skill missing from archive: $skill_name"
  cp -R "$source_dir" "$PROJECT_ROOT/.codex/skills/$skill_name"
done < "$incoming_skills"

if [ -f "$EXTRACT_DIR/scripts/update-codex-skills.sh" ]; then
  mkdir -p "$PROJECT_ROOT/scripts"
  cp "$EXTRACT_DIR/scripts/update-codex-skills.sh" "$PROJECT_ROOT/scripts/update-codex-skills.sh"
  chmod +x "$PROJECT_ROOT/scripts/update-codex-skills.sh"
fi

mkdir -p "$PROJECT_ROOT/.codex"
python3 - "$INCOMING_MANIFEST" "$PROJECT_ROOT/.codex/flutter-mvvm-skills.json" "$REPO" "$ASSET_NAME" "$VERSION" "$incoming_skills" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

incoming_manifest = Path(sys.argv[1])
target_manifest = Path(sys.argv[2])
repo = sys.argv[3]
asset = sys.argv[4]
requested_version = sys.argv[5]
incoming_skills = Path(sys.argv[6])

if incoming_manifest.is_file():
    data = json.loads(incoming_manifest.read_text(encoding="utf-8"))
else:
    data = {}

data["source"] = f"github.com/{repo}"
data["repo"] = repo
data["asset"] = asset
if requested_version:
    data["version"] = requested_version
data["installedAt"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
managed_skills = data.get("managedSkills") or [
    line.strip()
    for line in incoming_skills.read_text(encoding="utf-8").splitlines()
    if line.strip()
]
data["managedSkills"] = sorted(managed_skills)

target_manifest.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

installed_version="$(python3 - "$PROJECT_ROOT/.codex/flutter-mvvm-skills.json" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(data.get("version", "unknown"))
PY
)"

echo "Updated Flutter MVVM Codex skills to ${installed_version}."
