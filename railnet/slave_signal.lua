local store=dofile('/railnet/lib/store.lua')
local T=dofile('/railnet/lib/transport.lua')

local CFG=store.load('/railnet/device_config.lua') or {role='signal'}
local hwId = (CFG.options and CFG.options.hwId) or (os.getComputerLabel() or "SIG")
local mode = (CFG.options and CFG.options.mode) or "redstone"
local side = (CFG.options and CFG.options.side) or "right"
local periph= (CFG.options and CFG.options.periph) or nil

print('Signal-Slave gestartet: '..hwId)

local function setOutput(state)
  if mode=='redstone' and redstone and redstone.setOutput then
    redstone.setOutput(side, state and true or false)
  elseif mode=='periph' and periph and peripheral and peripheral.wrap then
    local dev=peripheral.wrap(periph)
    if dev then
      if state and dev.turnOn then dev.turnOn() elseif (not state) and dev.turnOff then dev.turnOff() end
    end
  end
end

while true do
  local msg=T.receive()
  if msg and msg.kind=='signal:set' and msg.payload then
    local id = msg.payload.id or msg.payload.hwId
    if id==hwId then
      print('Signal '..hwId..' -> '..tostring(msg.payload.on))
      setOutput(msg.payload.on)
    end
  elseif msg and msg.kind=='diag:ping' then
    T.broadcast('diag:pong',{label=os.getComputerLabel(),role=CFG.role})
  end
end
