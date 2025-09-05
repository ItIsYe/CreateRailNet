# CreateRailNet – Server Admin Guide

## Voraussetzungen
- Minecraft 1.21.x mit **CC:Tweaked** + **Create**
- CC:Tweaked **http** aktiviert (für GitHub-Download)
- GitHub Repo mit kompletter Struktur (siehe README)

## Erstinstallation auf einem PC (Ingame)
1. **Bootstrap** ausführen (siehe README, `<USER>` ersetzen)
2. `installer.lua --config` → Quelle bestätigen → Dateien werden geladen
3. `/railnet/installer.lua` starten → Rolle wählen (master / station / signal / display / sensor / pa)
4. **Reboot** (falls nicht automatisch)

## Updates
- Am **Master** im Tab **Provision**: `Quelle verteilen` → `UPDATE` oder `UPDATE --force`
- Slaves ziehen Dateien aus GitHub; Configs bleiben erhalten (außer `--force`)

## Backups (Master)
- Tab **Settings** → `Backup erstellen` / `Neueste wiederherstellen`
- Speicherort: `/.railnet_backups/`

## Notfall / Diagnose
- `diag:ping` via Master ausgelöst (implizit) – Slaves antworten mit `diag:pong`
- Globaler Not-Halt ist vorbereitet (künftiger Patch)
