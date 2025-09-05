# CreateRailNet – CC:Tweaked + Create Trains Control
Version: v4.3.3  
Minecraft: 1.21  
Mods: Create, CC:Tweaked

## Was ist das?
CreateRailNet ist ein modulares Zugleit- & Anzeige-System für Create-Züge mit CC:Tweaked-Computern. Es bietet eine Master-GUI, Fahrplanausspielung an Monitore, PA-Ansagen, Signal-/Weichensteuerung und ein Remote-Provisioning (Rollen/Updates/Reboot) für alle Slaves – ohne manuelle Datei-Kopien.

## Features (Stand v4.3.3)
- Master-GUI Tabs: **Fahrplan**, **Provision**, **Settings**
- ETA-Grundlage & Fahrplan-Generator pro Linie (Headway/Offset)
- Dual-Transport: Capella (rohes Modem) + Rednet (gemischt nutzbar)
- Provision-Agent: Rolle/Label setzen, Quelle verteilen, Update/Force-Update, Reboot
- Backups am Master (Manuell, einfache Verwaltung)
- Slaves: **station** (Abfahrt), **signal** (Signale/Weichen), **display** (Abfahrtsmonitor), **sensor** (Stub), **pa** (Lautsprecher)

## Installation (Serverfreundlich)
1) **Bootstrap via Pastebin** (lädt nur den Root-Installer von GitHub):
```lua
-- bootstrap for CreateRailNet
local repo = "https://raw.githubusercontent.com/<USER>/CreateRailNet/main/"
local h = http.get(repo.."installer.lua")
if not h then error("HTTP fehlgeschlagen: installer.lua") end
local d=h.readAll(); h.close()
local w=fs.open("installer.lua","w") w.write(d) w.close()
shell.run("installer.lua --config")
```
➡️ `<USER>` anpassen. Danach Quelle (User/Repo/Branch) bestätigen.

2) **Rollen setzen**
- `/railnet/installer.lua` auf jedem PC starten und Rolle wählen **oder** am Master im Tab **Provision** per Button verteilen.

3) **Starten**
- `startup.lua` startet **Provision-Agent** + jeweilige **Rolle** (kein Auto-Installer!).

## Ordnerstruktur
```
/
├─ README.md
├─ README_Server_Admins.md
├─ installer.lua
├─ startup.lua
└─ railnet/
   ├─ installer.lua
   ├─ master.lua
   ├─ provision_agent.lua
   ├─ slave_display.lua
   ├─ slave_signal.lua
   ├─ slave_sensor.lua
   ├─ slave_station.lua
   ├─ slave_pa.lua
   ├─ device_config.lua.sample
   └─ lib/
      ├─ store.lua
      ├─ ui.lua
      ├─ transport.lua
      ├─ eta.lua
      ├─ backups.lua
      ├─ yard.lua
      ├─ routes.lua
      ├─ diagnostics.lua
      ├─ checklist.lua
      ├─ common.lua
      ├─ timetable.lua
      ├─ scheduler.lua
      └─ conflicts.lua
```

## Lizenz
MIT (oder nach Wunsch anpassen)
