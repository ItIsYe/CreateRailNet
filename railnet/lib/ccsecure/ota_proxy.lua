-- railnet/lib/ccsecure/ota_proxy.lua  (Chunked OTA via Events)
-- MIT License © Merge Pack
local bus = require and require("railnet.lib.ccsecure.bus") or dofile("/railnet/lib/ccsecure/bus.lua")
local P = {}

local function chunk_bytes(s, size)
  size=size or 8192; local t,i,n={},1,#s
  while i<=n do t[#t+1]=s:sub(i,math.min(i+size-1,n)); i=i+size end
  return t
end

function P.master_broadcast(manifest, bundle_str, opts)
  opts=opts or {}; local chunks=chunk_bytes(bundle_str, opts.size or 8192)
  local key=(manifest.version or "v0")..":"..#chunks
  bus.publish("ota/announce", { key=key, manifest=manifest, chunks=#chunks })
  for i,data in ipairs(chunks) do bus.publish("ota/chunk/"..key.."/"..i, { idx=i, data=data }) end
  bus.publish("ota/complete", { key=key })
  return true
end

function P.client_listen(on_complete)
  local buf, key, total = {}, nil, 0
  bus.subscribe("ota/announce", function(p) key=p.key; total=p.chunks; buf={} end)
  bus.subscribe("ota/chunk/*", function(p, from, topic) if key and topic:find(key,1,true) then buf[p.idx]=p.data end end)
  bus.subscribe("ota/complete", function(p) if p.key==key then local out=table.concat(buf); if on_complete then pcall(on_complete, key, out) end; key,total,buf=nil,0,{} end end)
end

return P
