-- /startup.lua — CreateRailNet v4.3.3
-- Startet die konfigurierte Rolle + Provision-Agent. Installer NICHT automatisch.

local function exists(p) return fs.exists(p) end
local function loadtbl(p)
  if not exists(p) then return nil end
  local ok,res=pcall(function() local f=loadfile(p); return f and f() end)
  return ok and res or nil
end

local function start_role(role)
  if role=='master' then shell.run('/railnet/master.lua')
  elseif role=='station' then shell.run('/railnet/slave_station.lua')
  elseif role=='signal' then shell.run('/railnet/slave_signal.lua')
  elseif role=='display' then shell.run('/railnet/slave_display.lua')
  elseif role=='sensor' then shell.run('/railnet/slave_sensor.lua')
  elseif role=='pa' then shell.run('/railnet/slave_pa.lua')
  else print('Unbekannte Rolle: '..tostring(role)) end
end

local function main()
  if not exists('/railnet/provision_agent.lua') then
    print('Fehlt: /railnet/provision_agent.lua  -> installer.lua manuell ausführen.')
    return
  end
  local cfg = loadtbl('/railnet/device_config.lua')
  parallel.waitForAny(function()
    shell.run('/railnet/provision_agent.lua')
  end, function()
    if not cfg or not cfg.role then
      print('Keine Geräte-Konfiguration. Bitte /railnet/installer.lua ausführen.')
      while true do os.sleep(9999) end
    end
    print('Starte Rolle: '..tostring(cfg.role))
    start_role(cfg.role)
  end)
end

local ok,err=pcall(main)
if not ok then printError('Startup-Fehler: '..tostring(err)) end
