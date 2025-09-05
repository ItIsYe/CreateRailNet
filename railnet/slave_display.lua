local store=dofile('/railnet/lib/store.lua')
local T=dofile('/railnet/lib/transport.lua')
local ui=dofile('/railnet/lib/ui.lua')

local CFG=store.load('/railnet/device_config.lua') or {role='display'}
local mon=peripheral.find('monitor') or term
if mon.setTextScale then mon.setTextScale(0.5) end

print('Display-Slave gestartet: '..(CFG.options and CFG.options.stationKey or '*'))

while true do
  local msg=T.receive()
  if msg and msg.kind=='timetable:rows' and msg.payload then
    ui.clear(mon); ui.tag(mon,2,1,'Fahrplan',colors.cyan)
    local y=3
    for _,row in ipairs(msg.payload.rows or {}) do
      ui.tag(mon,2,y,string.format('%s %s %s %s→%s Gl%s ETA:%s %s',row.time,row.ttype,row.line,row.from,row.to,row.track,row.eta,row.status))
      y=y+1; if y>18 then break end
    end
  elseif msg and msg.kind=='diag:ping' then
    T.broadcast('diag:pong',{label=os.getComputerLabel(),role=(CFG.role or 'display'),stationKey=(CFG.options and CFG.options.stationKey)})
  end
end
