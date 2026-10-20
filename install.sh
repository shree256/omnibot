#!/bin/zsh
# Install (or remove) the launchd job that runs `omnibot.sh poll` for this folder.
#   ./install.sh             install / reinstall (run again after moving the folder)
#   ./install.sh --uninstall remove
set -euo pipefail

FB="${0:A:h}"
LABEL="com.omnibot.poll"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST"
[[ "${1:-}" == "--uninstall" ]] && { echo "omnibot: uninstalled"; exit 0; }

for tool in claude git jq gh; do
  command -v $tool >/dev/null || { echo "omnibot: '$tool' not found" >&2; exit 1; }
done

INTERVAL=$(source "$FB/config.sh"; echo "${POLL_INTERVAL:-600}")
chmod +x "$FB/omnibot.sh"

mkdir -p "$HOME/Library/LaunchAgents" "$FB/state"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>$FB/omnibot.sh</string><string>poll</string></array>
  <key>WorkingDirectory</key><string>$FB</string>
  <key>StartInterval</key><integer>$INTERVAL</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$FB/state/poll.log</string>
  <key>StandardErrorPath</key><string>$FB/state/poll.log</string>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "omnibot: installed — polling every ${INTERVAL}s from $FB (log: state/poll.log)"
