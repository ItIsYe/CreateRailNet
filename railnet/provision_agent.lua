local store=dofile('/railnet/lib/store.lua')
local T=dofile('/railnet/lib/transport.lua')

local function saveInstallerCfg(src)
  local path='/installer_cfg.lua'
  return store.save(path, src or {})
end

local function saveDeviceCfg(mut)
  local path='/railnet/device_config.lua'
  local cfg=store.load(path) or {role=nil, options={}, net={namespace='CreateRailNet',app_id=27182,proto='crn.v1'}, transports={capella=true,rednet=true}}
  for k,v in pairs(mut or {}) do cfg[k]=v end
  return store.save(path,cfg)
end

local function setLabel(lbl)
  if lbl and lbl~='' then pcall(function() os.setComputerLabel(lbl) end) end
end

local function runInstaller(force)
  if not fs.exists('/installer.lua') then return false,'no_installer' end
  local arg = force and '--force' or ''
  local ok,err = pcall(function() shell.run('/installer.lua '..arg) end)
  return ok,err
end

while true do
  local msg=T.receive(0.5)
  if msg and msg.kind=='provision:set_source' then
    saveInstallerCfg(msg.payload or {})
  elseif msg and msg.kind=='provision:set_role' and msg.payload then
    saveDeviceCfg({ role = msg.payload.role, options = msg.payload.options or {} })
  elseif msg and msg.kind=='provision:set_label' and msg.payload then
    setLabel(msg.payload.label)
  elseif msg and msg.kind=='provision:install' then
    runInstaller(msg.payload and msg.payload.force)
  elseif msg and msg.kind=='provision:reboot' then
    os.reboot()
  elseif msg and msg.kind=='diag:ping' then
    local cfg=store.load('/railnet/device_config.lua') or {}
    T.broadcast('diag:pong',{label=os.getComputerLabel(),role=cfg.role,stationKey=(cfg.options and cfg.options.stationKey)})
  end
end
