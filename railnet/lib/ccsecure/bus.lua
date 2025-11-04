-- railnet/lib/ccsecure/bus.lua  (HMAC, ACK/Timeouts, Wildcards, RBAC)
-- MIT License © Merge Pack
local sec = require and require("railnet.lib.ccsecure.security") or dofile("/railnet/lib/ccsecure/security.lua")
local M = {}

local proto = "railnet_secure"
local node_id = os.getComputerID()
local rpc_handlers, subs, subs_wc, awaiting = {}, {}, {}, {}
local tx_counter = math.random(1000,9999)
local TIME_SKEW_MS = 10000

local function now() return os.epoch("utc") end
local function gen_txid() tx_counter=(tx_counter+1)%1000000; return ("%d-%d-%d"):format(node_id, now(), tx_counter) end
local function stable_serialize(t) return textutils.serialize(t) end
local function hmac(payload) return textutils.sha256((sec.load_secret().key or "dev").."|"..payload) end
local function open_modem() if rednet.isOpen() then return end; local side=peripheral.find("modem", function(_,m) return peripheral.call(m,"isWireless") end); if side then rednet.open(peripheral.getName(side)) end end
local function wc_to_lua(w) local p=w:gsub("([%^%$%(%)%%%.%+%-%?%[%]])","%%%1"):gsub("%*",".+"); return "^"..p.."$" end

function M.init()
  open_modem()
  if M._lst then return end; M._lst=true
  parallel.waitForAny(function()
    while true do
      local id, frame = rednet.receive(proto, 0.1)
      if id then
        local sig=frame.sig; frame.sig=nil
        local ok=(sig==hmac(stable_serialize(frame)))
        frame.sig=sig
        if ok and (not frame.ts or math.abs(now()-frame.ts)<=TIME_SKEW_MS) then
          if frame.txid and sec.nonce_seen(frame.txid) then
          else
            if frame.type=="event" then
              if subs[frame.topic] then for _,fn in ipairs(subs[frame.topic]) do pcall(fn, frame.payload, id, frame.topic) end end
              for _,rec in ipairs(subs_wc) do if frame.topic:match(rec.pat) then pcall(rec.fn, frame.payload, id, frame.topic) end end
            elseif frame.type=="rpc_res" then
              local w=awaiting[frame.txid]; if w then awaiting[frame.txid]=nil; pcall(w.cb, frame) end
            elseif frame.type=="rpc_req" then
              local rec=rpc_handlers[frame.method]; local resp={ type="rpc_res", from=node_id, to=frame.from, ts=now(), txid=frame.txid, ok=false }
              if rec and rec.handler then
                if not rec.scope or sec.allow(rec.scope) then
                  local ok2,res=pcall(rec.handler, frame.params, id); if ok2 then resp.ok=true; resp.result=res else resp.ok=false; resp.error=tostring(res) end
                else resp.ok=false; resp.error="rbac_denied" end
              else resp.ok=false; resp.error="no_handler" end
              resp.sig=hmac(stable_serialize(resp)); rednet.send(frame.from, resp, proto)
            end
          end
        end
      end
      local tnow=now(); for tx,w in pairs(awaiting) do if tnow>=w.deadline then local cb=w.cb; awaiting[tx]=nil; pcall(cb,{type="rpc_res",ok=false,error="timeout",txid=tx}) end end
    end
  end)
end

function M.subscribe(topic_or_wc, fn)
  if topic_or_wc:find("*",1,true) then
    table.insert(subs_wc,{pat=wc_to_lua(topic_or_wc), fn=fn})
  else
    subs[topic_or_wc]=subs[topic_or_wc] or {}
    table.insert(subs[topic_or_wc], fn)
  end
end

function M.publish(topic, payload)
  local f={type="event", topic=topic, payload=payload, from=node_id, ts=now(), txid=gen_txid()}
  f.sig=hmac(stable_serialize(f)); rednet.broadcast(f, proto)
end

function M.rpc_register(method, handler, scope)
  rpc_handlers[method]={handler=handler, scope=scope}
end

function M.rpc_call(target, method, params, opts)
  opts=opts or {}; local timeout=opts.timeout or 1.5; local retries=opts.retries or 2
  local txid=gen_txid(); local req={ type="rpc_req", from=node_id, to=target, method=method, params=params, ts=now(), txid=txid }
  req.sig=hmac(stable_serialize(req))
  local function once(deadline)
    local done,res=false,nil; awaiting[txid]={deadline=deadline, cb=function(fr) done=true; res=fr end}
    rednet.send(target, req, proto)
    local st=os.clock()
    while not done and (os.clock()-st)<timeout do os.pullEvent() end
    awaiting[txid]=nil
    return done,res
  end
  for i=0,retries do local ok,res=once(now()+math.floor(timeout*1000)); if ok then return res.ok,res.result,res.error end; sleep(0.1*(2^i)) end
  return false,nil,"timeout"
end

return M
