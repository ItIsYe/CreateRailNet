local store=dofile('/railnet/lib/store.lua')
local T={}
T.cfg=store.load('/railnet/device_config.lua') or {}
T.net=T.cfg.net or { namespace='CreateRailNet', app_id=27182, proto='crn.v1' }
T.use=(T.cfg.transports or {capella=true, rednet=true})

DEDUP=DEDUP or { last={}, order={} }
local MAX,TTL=512,60
local function seen(id) if not id then return false end; local now=os.epoch('utc')/1000; local e=DEDUP.last[id]; if e and (now-e.ts)<TTL then return true end; DEDUP.last[id]={ts=now}; table.insert(DEDUP.order,id); if #DEDUP.order>MAX then local o=table.remove(DEDUP.order,1); DEDUP.last[o]=nil end; return false end

local function modem_open()
  if not peripheral or not peripheral.find then return false end
  local md=peripheral.find('modem'); if not md then return false end
  local ch=20000+((tonumber(T.net.app_id) or 0)%40000)
  if not md.isOpen(ch) then md.open(ch) end; if not md.isOpen(0) then md.open(0) end
  return true,md,ch
end
modem_open() -- ensure receive channel open at init

local seq=0
local function pkt(kind,payload) seq=(seq+1)%65535; return { ns=T.net.namespace, app=T.net.app_id, proto=T.net.proto, kind=kind, payload=payload, msg_id=(T.net.namespace..'-'..T.net.app_id..'-'..os.epoch('utc')..'-'..seq) } end

function T.broadcast(kind,payload)
  local p=pkt(kind,payload); local s=textutils.serialize(p)
  local ok,md,ch=modem_open(); if (T.use.capella~=false) and ok then pcall(function() md.transmit(ch,ch,s) end) end
  if (T.use.rednet~=false) and _G.rednet and rednet.isOpen and rednet.isOpen() then pcall(function() rednet.broadcast(s, T.net.proto) end) end
end

function T.receive(timeout)
  local deadline=timeout and (os.clock()+timeout) or nil
  while true do
    local ev={os.pullEvent(timeout and 'modem_message' or nil)}
    if ev[1]=='modem_message' then
      local raw=ev[5]; if type(raw)=='string' then local ok,tab=pcall(textutils.unserialize,raw); if ok and tab and tab.ns==T.net.namespace and tab.app==T.net.app_id and not seen(tab.msg_id) then return tab end end
    elseif ev[1]=='rednet_message' and (T.use.rednet~=false) then
      local raw,proto=ev[3],ev[4]; if proto==T.net.proto and type(raw)=='string' then local ok,tab=pcall(textutils.unserialize,raw); if ok and tab and tab.ns==T.net.namespace and tab.app==T.net.app_id and not seen(tab.msg_id) then return tab end end
    end
    if deadline and os.clock()>deadline then return nil end
  end
end

return T
