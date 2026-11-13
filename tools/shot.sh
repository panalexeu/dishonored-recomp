#!/usr/bin/env bash
# Run the game with extra config lines and screenshot the window (graphics A/B testing).
#
#   tools/shot.sh <name> <seconds,...> [config line ...]
#   tools/shot.sh occl_off 60,75 "occlusion_query_enable = false"
#
# Extra lines are appended to a copy of config/dishonored.toml in the build dir for this run only
# (GPU plugin settings are read only from that file). Screenshots: out/shots/<name>_<sec>s.png
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
build="$root/out/build/${DISHONORED_BUILD:-linux-amd64-release}"
name="$1"; times="$2"; shift 2

if pgrep -f "out/build/.*/[d]ishonored --game_data_root" > /dev/null; then
  echo "another game instance is running; not starting a second one" >&2
  exit 1
fi

mkdir -p "$root/out/shots"
cp "$root/config/dishonored.toml" "$build/dishonored.toml"
if [ $# -gt 0 ]; then
  # Replace keys the config already sets (TOML rejects duplicates), then append the new values.
  for line in "$@"; do
    key="${line%%=*}"; key="${key// /}"
    sed -i "/^[[:space:]]*${key}[[:space:]]*=/d" "$build/dishonored.toml"
  done
  { echo; echo "# --- tools/shot.sh: $name ---"; printf '%s\n' "$@"; } >> "$build/dishonored.toml"
fi

setsid "$root/tools/run.sh" > "$root/out/shots/$name.stdout" 2>&1 &
game=$!  # run.sh execs the game, so this is its pid
# Never leave the game running, even if this script fails.
trap 'kill "$game" 2>/dev/null || true; cp "$root/config/dishonored.toml" "$build/dishonored.toml"' EXIT
start=$(date +%s)
last=0
IFS=, read -ra ts <<< "$times"
for t in "${ts[@]}"; do
  while [ $(( $(date +%s) - start )) -lt "$t" ]; do sleep 1; done
  wid=$(xwininfo -root -tree | awk '/"dishonored \[/ && !w {w=$1} END {print w}')  # no early exit: SIGPIPE + pipefail killed the script
  if [ -n "$wid" ]; then
    import -window "$wid" "$root/out/shots/${name}_${t}s.png" && echo "shot: out/shots/${name}_${t}s.png"
  else
    echo "no game window at ${t}s"
  fi
  last=$t
done

kill "$game" 2>/dev/null || true
wait "$game" 2>/dev/null || true
cp "$root/config/dishonored.toml" "$build/dishonored.toml"
log=$(ls -t "$build/logs" | head -1)
echo "log: $build/logs/$log"
