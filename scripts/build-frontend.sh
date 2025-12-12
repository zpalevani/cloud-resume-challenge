#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED_DIR="${ROOT_DIR}/frontend/shared"
FLAVORS_DIR="${ROOT_DIR}/frontend/flavors"
DIST_DIR="${ROOT_DIR}/frontend/dist"

mkdir -p "${DIST_DIR}"

build_one() {
  local flavor="$1"
  local flavor_file="${FLAVORS_DIR}/${flavor}.json"
  local out_dir="${DIST_DIR}/${flavor}"

  if [[ ! -f "${flavor_file}" ]]; then
    echo "Missing flavor file: ${flavor_file}"
    exit 1
  fi

  # Read the JSON text (fail fast if empty)
  if [[ ! -s "${flavor_file}" ]]; then
    echo "Flavor file is empty: ${flavor_file}"
    exit 1
  fi

  rm -rf "${out_dir}"
  mkdir -p "${out_dir}"

  cp -R "${SHARED_DIR}/." "${out_dir}/"

  python3 - "${flavor_file}" "${out_dir}" << 'PY'
import json, sys, pathlib

flavor_path = pathlib.Path(sys.argv[1])
out_dir = pathlib.Path(sys.argv[2])

raw = flavor_path.read_text(encoding="utf-8").strip()
if not raw:
    raise SystemExit(f"Flavor JSON is empty: {flavor_path}")

data = json.loads(raw)

for path in out_dir.rglob("*"):
    if path.is_file() and path.suffix.lower() in {".html", ".css", ".js"}:
        text = path.read_text(encoding="utf-8")
        for k, v in data.items():
            text = text.replace(f"__{k}__", str(v))
        path.write_text(text, encoding="utf-8")

print(f"Built: {out_dir}")
PY
}

if [[ "${1:-}" != "" ]]; then
  build_one "$1"
else
  build_one "aws"
  build_one "azure"
  build_one "gcp"
fi
