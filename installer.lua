-- installer.lua — CreateRailNet v4.3.3 (Root-Installer)
-- Lädt/aktualisiert alle Dateien aus dem GitHub-Repo.
-- Konfig: /installer_cfg.lua  (GITHUB_USER, REPO, BRANCH, preserve)

local CFG_PATH = "/installer_cfg.lua"
local DEFAULT = { GITHUB_USER="<USER>", REPO="CreateRailNet", BRANCH="main", preserve=true }

local function loadCfg()
  if fs.exists(CFG_PATH) then
    local ok,res = pcall(function() local f=loadfile(CFG_PATH); return f and f() end)
    if ok and type(res)=="table" then return res end
  end
  return DEFAULT
end

local function saveCfg(cfg)
  local h=fs.open(CFG_PATH,"w"); h.write("return "..textutils.serialize(cfg)); h.close()
end

local function ask(p, def)
  write(p.." ["..(def or "").."]: ")
  local v = read()
  return (v=="" and def) or v
end

local args={...}; local FORCE=false; local MODE=nil
for i=1,#args do
  if args[i]=="--force" then FORCE=true end
  if args[i]=="--config" then MODE="config" end
end

local CFG = loadCfg()
if MODE=="config" or CFG.GITHUB_USER=="<USER>" then
  print("GitHub-Quelle konfigurieren:")
  CFG.GITHUB_USER = ask("GitHub User/Org", CFG.GITHUB_USER or "")
  CFG.REPO        = ask("Repository",      CFG.REPO or "CreateRailNet")
  CFG.BRANCH      = ask("Branch",          CFG.BRANCH or "main")
  local pres      = ask("Lokale Configs bewahren? (y/n)", (CFG.preserve==false) and "n" or "y")
  CFG.preserve    = (pres:lower() ~= "n")
  saveCfg(CFG)
end

local function baseUrl()
  return ("https://raw.githubusercontent.com/%s/%s/%s/"):format(CFG.GITHUB_USER, CFG.REPO, CFG.BRANCH)
end

local FILES = {
  "startup.lua",
  "railnet/installer.lua",
  "railnet/master.lua",
  "railnet/provision_agent.lua",
  "railnet/slave_station.lua",
  "railnet/slave_signal.lua",
  "railnet/slave_display.lua",
  "railnet/slave_sensor.lua",
  "railnet/slave_pa.lua",
  "railnet/lib/store.lua",
  "railnet/lib/ui.lua",
  "railnet/lib/transport.lua",
  "railnet/lib/eta.lua",
  "railnet/lib/backups.lua",
  "railnet/lib/yard.lua",
  "railnet/lib/routes.lua",
  "railnet/lib/diagnostics.lua",
  "railnet/lib/checklist.lua",
  "railnet/lib/common.lua",
  "railnet/lib/timetable.lua",
  "railnet/lib/scheduler.lua",
  "railnet/lib/conflicts.lua",
  "railnet/device_config.lua.sample",
  "README_Server_Admins.md",
  "README.md"
}

local PRESERVE = {
  ["railnet/device_config.lua"]=true,
  ["railnet/master.db"]=true,
  ["installer_cfg.lua"]=true
}

local function ensureDir(p)
  local d = p:match("(.+)/[^/]+$")
  if d and d~="" and not fs.isDir(d) then fs.makeDir(d) end
end

local function download(path)
  local url = baseUrl()..path
  local h,err = http.get(url)
  if not h then
    print("HTTP Fehler: "..tostring(err or "?").." @ "..url)
    return false
  end
  local data=h.readAll(); h.close()
  ensureDir(path)
  local f=fs.open(path,"w"); f.write(data); f.close()
  return true
end

print(("Quelle: %s/%s @ %s"):format(CFG.GITHUB_USER, CFG.REPO, CFG.BRANCH))
for _,file in ipairs(FILES) do
  if (CFG.preserve and PRESERVE[file] and fs.exists(file) and not FORCE) then
    print("• Überspringe (preserve): "..file)
  else
    print("→ Lade "..file)
    if not download(file) then print("!! Fehler: "..file) end
  end
end

print("Installation/Update abgeschlossen.")
print("Hinweis: Installer startet nichts automatisch.")
print("• Erstkonfiguration: /railnet/installer.lua")
print("• Danach reboot, startup lädt Rolle + Provision-Agent.")
