local store=dofile('/railnet/lib/store.lua')
local CFG=store.load('/railnet/device_config.lua') or { role=nil, options={}, net={namespace='CreateRailNet',app_id=27182,proto='crn.v1'}, transports={capella=true,rednet=true} }

local function pickRole()
  term.clear(); term.setCursorPos(1,1)
  print('CreateRailNet Rollen-Installer')
  print('1) master  2) signal  3) display  4) sensor  5) pa')
  write('> '); local n=tonumber(read()) or 1
  CFG.role=({'master','signal','display','sensor','pa'})[math.max(1,math.min(5,n))]
  print('Optional: Label setzen (Enter zum Überspringen):')
  local lbl=read(); if lbl and lbl~='' then os.setComputerLabel(lbl) end
  if CFG.role=='display' then
    print('StationKey für Anzeige (* = alle):'); CFG.options.stationKey=read()
    print('Filter (ALL/P_ONLY/G_ONLY) [ALL]:'); local f=(read() or ''):upper(); CFG.options.display_filter = (f=='P_ONLY' or f=='G_ONLY') and f or 'ALL'
  elseif CFG.role=='signal' then
    print('StationKey:'); CFG.options.stationKey = read()
    print('Hardware-ID (logische ID):'); CFG.options.hwId = read()
    print('Mode (redstone/periph) [redstone]:'); local m=read(); CFG.options.mode = (m~='' and m) or 'redstone'
    print('Side [right]:'); local s=read(); CFG.options.side = (s~='' and s) or 'right'
  elseif CFG.role=='sensor' then
    print('StationKey:'); CFG.options.stationKey = read()
    print('Block-ID (Sensorname):'); CFG.options.blockId = read()
  elseif CFG.role=='pa' then
    print('StationKey:'); CFG.options.stationKey = read()
  end
  store.save('/railnet/device_config.lua', CFG)
end

if not CFG.role then pickRole() else print('Rolle bereits gesetzt: '..tostring(CFG.role)) end
