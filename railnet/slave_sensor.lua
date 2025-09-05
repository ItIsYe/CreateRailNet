local store=dofile('/railnet/lib/store.lua')
local T=dofile('/railnet/lib/transport.lua')

local CFG=store.load('/railnet/device_config.lua') or {role='sensor'}
print('Sensor-Slave gestartet: '..(CFG.options and CFG.options.blockId or '?'))

while true do
  local msg=T.receive(1)
  if msg and msg.kind=='diag:ping' then
    T.broadcast('diag:pong',{label=os.getComputerLabel(),role=CFG.role,stationKey=(CFG.options and CFG.options.stationKey)})
  end
  -- TODO: echte Sensorabfrage + T.broadcast('sensor:hit', {blockId=..., stationKey=...})
end
