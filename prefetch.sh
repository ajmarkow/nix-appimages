set -euo pipefail

if [ $# -lt 1 ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "usage: prefetch-appimage <url> [name]" >&2
  echo "prints a ready-to-paste programs.appimages.apps entry" >&2
  exit 1
fi

url="$1"
name="${2:-myapp}"

json="$(nix store prefetch-file --json "$url")"
hash="$(printf '%s' "$json" | jq -r '.hash')"

cat <<EOF
apps.${name} = {
  url = "${url}";
  hash = "${hash}";
  version = "1.0.0";
};
EOF
