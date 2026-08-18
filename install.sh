#!/bin/bash
# ccdash paigaldus (macOS).
#
# Teeb neli asja:
#   1. symlingid  repo -> ~/.claude/scripts/
#   2. seadistuse ~/.claude/ccdash.config.json (kui puudub)
#   3. launchd    ~/Library/LaunchAgents/eu.vibetec.*.plist (kui puuduvad)
#   4. käivitab   serveri
#
# EI KIRJUTA MIDAGI ÜLE. Kui mõni fail on juba olemas ja ei ole symlink sellesse
# repo, skript peatub ja ütleb, mis takistab — nii ei hävita ta töötavat
# seadistust, mis paigaldati enne repo tekkimist.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$HOME/.claude/scripts"
AGENTS="$HOME/Library/LaunchAgents"
CONFIG="$HOME/.claude/ccdash.config.json"

mkdir -p "$SCRIPTS" "$AGENTS" "$HOME/.claude/logs"

link() {                       # link <allikas> <sihtnimi>
  local src="$1" dst="$SCRIPTS/$2"
  [ -f "$src" ] || { echo "STOP: $src puudub — kas repo on terve?" >&2; exit 1; }
  if [ -L "$dst" ]; then
    local cur; cur="$(readlink "$dst")"
    [ "$cur" = "$src" ] && { echo "  = $2 (juba paigas)"; return; }
    echo "STOP: $dst on symlink mujale: $cur" >&2; exit 1
  fi
  if [ -e "$dst" ]; then
    echo "STOP: $dst on juba olemas ja ei ole symlink." >&2
    echo "      Kui see on sinu vana paigaldus, tee varukoopia ja kustuta see fail." >&2
    exit 1
  fi
  ln -s "$src" "$dst"; echo "  + $2"
}

echo "1/4 symlingid -> $SCRIPTS"
link "$REPO/bin/ccdash"                ccdash
link "$REPO/bin/ccdash-open"           ccdash-open
link "$REPO/bin/token-usage-daily.sh"  token-usage-daily.sh
link "$REPO/src/ccdash.py"             ccdash.py
link "$REPO/src/ccusage_lib.py"        ccusage_lib.py
link "$REPO/src/token_usage_daily.py"  token_usage_daily.py

echo "2/4 seadistus"
if [ -e "$CONFIG" ]; then
  echo "  = $CONFIG on olemas, ei puutu"
else
  cp "$REPO/examples/ccdash.config.json" "$CONFIG"
  echo "  + $CONFIG — TÄIDA projectRoots enne kasutamist (vt README)"
fi
if [ ! -e "$HOME/.claude/ccusage.json" ]; then
  cp "$REPO/examples/ccusage.json" "$HOME/.claude/ccusage.json"
  echo "  + ~/.claude/ccusage.json (hinnaülekirjutused)"
fi

echo "3/4 launchd"
for label in eu.vibetec.ccdash eu.vibetec.token-usage-daily; do
  plist="$AGENTS/$label.plist"
  if [ -e "$plist" ]; then
    echo "  = $label.plist on olemas, ei puutu"
  else
    sed "s#__HOME__#$HOME#g" "$REPO/launchd/$label.plist.template" > "$plist"
    echo "  + $label.plist"
  fi
done

echo "4/4 käivitan"
launchctl bootout "gui/$(id -u)/eu.vibetec.ccdash" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENTS/eu.vibetec.ccdash.plist"
launchctl bootout "gui/$(id -u)/eu.vibetec.token-usage-daily" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENTS/eu.vibetec.token-usage-daily.plist"

echo
echo "Valmis. Ava dashboard:  ~/.claude/scripts/ccdash-open"
echo "Esimene laadimine võtab ~10 s (npx ccusage)."
