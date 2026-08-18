#!/bin/bash
# Igapäevane Claude Code token-kasutuse jälgija (launchd: ee.ppo.token-usage-daily, 9:00).
#
# See fail on ainult käivitaja — kogu loogika on token_usage_daily.py-s ja
# ccusage_lib.py-s. Nimi peab jääma, sest ~/Library/LaunchAgents/ee.ppo.token-usage-daily.plist
# osutab sellele.
#
# Ajalugu: vana bash-versioon kirjutas hinnakirja kao korral vaikselt "$0.00" ja
# arvutas kuu kumulatiivi ccusage'ist, mis kaotab vana ajaloo -> kumulatiiv kahanes.
# Mõlemad parandatud 2026-08-11, vt kommentaare Python-failides.

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

exec /usr/bin/env python3 "$HOME/.claude/scripts/token_usage_daily.py" "$@"
