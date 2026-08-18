# ccdash

Claude Code'i kasutuse dashboard: mis projekt sinu kvooti sööb, kui suureks on
sessioonid paisunud ja kui palju kuu seni maksnud on. Üks Pythoni fail serveerib
kogu HTML-i, sõltuvusi peale standardteegi ja `npx ccusage` ei ole.

> **In English:** a local dashboard for Claude Code usage, built on `ccusage`.
> Code comments, UI and docs are in Estonian. The part worth reading even if you
> don't speak Estonian is [`src/ccusage_lib.py`](src/ccusage_lib.py) — it documents
> three ways `ccusage` silently reports wrong numbers, and how to detect each.

![ccdash](docs/screenshot.png)

*Ekraanipilt on tehtud demo-režiimis (`CCDASH_DEMO=1`) — numbrid on päris, projekti-
ja sessiooninimed asendatud.*

## Miks see olemas on

Dashboard ise on kaunistus. Väärtus on `src/ccusage_lib.py` päises: **kolm viisi,
kuidas `ccusage` vaikselt valesid numbreid annab** — mõõdetud, mitte teoreetilised.

1. **Hinnakiri kaob.** Claude Code'i `.jsonl`-id ei sisalda `costUSD` välja
   (tellimuskasutus), seega kulu arvutatakse ALATI võrgust tõmmatud hinnatabelist.
   Tõmbe ebaõnnestumisel ei tule viga — tuleb `totalCost: 0` ja normaalsed
   tokeninumbrid. Nii tekkis logisse `$0.00 / 129 759 914 tok`, kui tegelik kulu
   oli `$99.26`.
2. **Hinnakiri võib kaduda OSALISELT** — ja see on salakavalam. `ccusage` 20.0.19
   offline-tabelis puudus `claude-opus-5`: `--offline` andis $1955, õige oli $3266.
   Rea kogusumma kontroll ei päästa, sest segapäeval on `totalCost` nullist erinev.
   → kontrolli **mudelite kaupa** (`modelBreakdowns`), mitte rea summat.
3. **Ajalugu kustub.** Claude Code koristab vanu transkripte, seega ajaloolised
   summad KAHANEVAD ajas (juuli: $2606 → hiljem $2187). Kuu kumulatiivi ei tohi
   `ccusage`'ist arvutada — see tuleb liita oma logist.

Lisaks: `check_pricing_drift()` võrdleb sinu hinnaülekirjutusi LiteLLM-i tabeliga
ja hoiatab, kui need lahku lähevad.

## Paigaldus

Nõuded: macOS, Python 3.11+, Node (`npx`), soovi korral Google Chrome (äpiaken).

```bash
git clone https://github.com/hv-tec/ccdash.git ~/dev/ccdash
cd ~/dev/ccdash && ./install.sh
```

`install.sh` teeb symlingid `~/.claude/scripts/` alla, paigaldab kaks launchd-jobi
ja käivitab serveri. **Ta ei kirjuta midagi üle** — kui mõni fail on juba olemas ja
ei ole symlink sellesse repo, ta peatub ja ütleb, mis takistab.

> ⚠️ Kui sul on ccdash juba käsitsi paigaldatud (failid, mitte symlingid
> `~/.claude/scripts/` all), **ära jooksuta `install.sh`** — asenda failid ise
> symlinkidega või jäta vanad alles. Skript on värske klooni jaoks.

Eemaldus: `./uninstall.sh` (logi ja seadistus jäävad alles).

## Seadistus

`~/.claude/ccdash.config.json`, näidis [`examples/ccdash.config.json`](examples/ccdash.config.json).
Kõik väljad on valikulised.

| Väli | Mida teeb |
|---|---|
| `projectRoots` | Kaustad, mille alamkaustad on projektid. **Loetle kõik puud**, kus projektid elavad. |
| `timezone` | Päevade grupeerimine. Puudumisel süsteemi oma. |
| `thresholds.monthEur` | Kuu hoiatuslävi dashboardil (EUR). |
| `thresholds.dayUsd` / `monthUsd` | Päevalogija macOS-teate läved (USD). |

**Miks `projectRoots` tuleb käsitsi loetleda.** Claude Code hoiab transkripte
kaustanime järgi, kus teest on tehtud slug: `/Users/x/Projects/veeb` →
`-Users-x-Projects-veeb`. Teisendus **ei ole pööratav** — sidekriipsuks muutuvad ka
`.` ja `@`, seega tagasi ei saa. Seepärast loeb ccdash projekti transkripti
`cwd`-väljast ja peab teadma, millised teed on projektijuured. Nende tuletamine
kodukaustast ei tööta.

## Kasutus

```bash
~/.claude/scripts/ccdash              # server + brauser
~/.claude/scripts/ccdash-open         # Chrome'i äpiaken (eraldi profiil)
CCDASH_DEMO=1 ~/.claude/scripts/ccdash   # demo-režiim, vt allpool
python3 src/token_usage_daily.py --dry-run   # päevarida, ilma kirjutamata
```

Server on laisk: kui keegi ei polli, ta magab ega jooksuta `ccusage`'it. Seepärast
on turvaline hoida teda launchd all kogu aeg.

**Demo-režiim.** `CCDASH_DEMO=1` asendab projektinimed `demo1…demoN` (kulu
järjekorras) ja sessioonipealkirjad üldistega. Kulud, tokenid ja ajad jäävad päris.
Mõeldud ekraanipildi või esitluse jaoks — sessioonipealkirjad tulevad `aiTitle`
väljast ja on vabas vormis laused päris tööst.

**Päevalogija** (`launchd`, 9:00) kirjutab rea faili
`~/.claude/logs/token-usage-daily.log`. See on **ainus püsiv kasutusajalugu** —
`ccusage` kaotab vanad päevad ja neid ei saa taastada. Ära kustuta seda faili ega
"ehita uuesti üles".

## Struktuur

```
bin/       ccdash, ccdash-open, token-usage-daily.sh   käivitajad
src/       ccdash.py (server + kogu UI), ccusage_lib.py (teek), token_usage_daily.py
launchd/   plist-mallid (__HOME__ asendatakse paigaldusel)
macos/     ClaudeUsage.applescript — Desktopi äpi lähtekood (binaari ei commitita)
examples/  ccdash.config.json, ccusage.json
```

## Mida see EI tee

- **Ei näita protsenti limiidist.** Anthropic ei avalda limiiti üheski masinloetavas
  kohas (kontrollitud: transkriptid, logid, vahemälu, `~/.claude.json`). Näidatakse
  tegelikke mahtusid ja lähtestamisaegu. Protsent: claude.ai → Settings → Usage.
- **Ei ole mitmeplatvormiline.** launchd, `osascript`-teated ja Chrome'i äpiaken on
  macOS-i omad. Server ise (`python3 src/ccdash.py --port 8787`) töötab igal pool.
- **Ei saada andmeid kuhugi.** Kõik jääb masinasse; võrku minnakse ainult EKP
  kursi, LiteLLM-i hinnatabeli ja `npx` pärast.

MIT.
