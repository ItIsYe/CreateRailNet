local store=dofile('/railnet/lib/store.lua')
local T=dofile('/railnet/lib/transport.lua')

local CFG=store.load('/railnet/device_config.lua') or {role='pa'}
local spk=peripheral.find('speaker')
print('PA-Slave gestartet: '..(CFG.options and CFG.options.stationKey or '*'))

while true do
  local msg=T.receive()
  if msg and msg.kind=='pa:announce' and msg.payload then
    local st=msg.payload.stationKey
    if (st=='*') or (CFG.options and CFG.options.stationKey==st) then
      print('Ansage: '..tostring(msg.payload.text))
      if spk and spk.playSound then spk.playSound("minecraft:block.note_block.pling", msg.payload.volume or 2) end
    end
  elseif msg and msg.kind=='diag:ping' then
    T.broadcast('diag:pong',{label=os.getComputerLabel(),role=CFG.role,stationKey=(CFG.options and CFG.options.stationKey)})
  end
end
