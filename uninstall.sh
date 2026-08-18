#!/bin/bash
# ccdash eemaldus. Võtab maha symlingid, launchd-jobid ja plistid.
#
# EI KUSTUTA:
#   ~/.claude/logs/token-usage-daily.log  — ainus PÜSIV kasutusajalugu; ccusage
#                                            kaotab vanad päevad, seda ei saa taastada
#   ~/.claude/ccdash.config.json          — sinu seadistus
#   repo ennast

set -euo pipefail
SCRIPTS="$HOME/.claude/scripts"
AGENTS="$HOME/Library/LaunchAgents"

for label in ee.ppo.ccdash ee.ppo.token-usage-daily; do
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  rm -f "$AGENTS/$label.plist" && echo "- $label"
done

for f in ccdash ccdash-open token-usage-daily.sh ccdash.py ccusage_lib.py token_usage_daily.py; do
  if [ -L "$SCRIPTS/$f" ]; then rm "$SCRIPTS/$f"; echo "- $f"
  elif [ -e "$SCRIPTS/$f" ]; then echo "! $f ei ole symlink — jätan alles"; fi
done

echo
echo "Alles jäid: logi (~/.claude/logs/token-usage-daily.log), seadistus ja repo."
