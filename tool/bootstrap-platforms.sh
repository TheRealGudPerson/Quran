#!/usr/bin/env bash
set -euo pipefail

# Generate official native scaffolding in a temporary directory and copy only
# missing platform folders into this checkout. Existing platform files remain
# untouched. Run from the repository root with Flutter installed.
if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: Flutter is not installed or is not on PATH." >&2
  exit 1
fi

if [[ ! -f pubspec.yaml ]]; then
  echo "Error: run this script from the Quran repository root." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

flutter create \
  --platforms=android,linux,macos,windows \
  --org=org.quranreader \
  --project-name=quran_reader \
  "$tmp_dir/quran_reader"

for platform in android linux macos windows; do
  if [[ -e "$platform" ]]; then
    echo "Preserving existing $platform/ directory."
  else
    cp -a "$tmp_dir/quran_reader/$platform" "$platform"
    echo "Added $platform/ scaffolding."
  fi
done

echo "Platform scaffolding complete. Review generated files before committing."
