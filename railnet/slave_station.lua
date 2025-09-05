local store=dofile('/railnet/lib/store.lua')
local T=dofile('/railnet/lib/transport.lua')

local CFG=store.load('/railnet/device_config.lua') or {role='station'}
print('Stations-Slave gestartet: '..(CFG.options and CFG.options.stationKey or '?'))

while true do
  local msg=T.receive()
  if msg and msg.kind=='station:depart' and msg.payload then
    if (CFG.options and CFG.options.stationKey)==msg.payload.stationKey then
      print('Abfahrt freigeben für Gleis '..tostring(msg.payload.track))
      -- TODO: Signal/Redstone/Create anstoßen
    end
  elseif msg and msg.kind=='diag:ping' then
    T.broadcast('diag:pong',{label=os.getComputerLabel(),role=CFG.role,stationKey=(CFG.options and CFG.options.stationKey)})
  end
end
