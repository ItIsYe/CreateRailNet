-- railnet/lib/transport_ccsecure.lua  (Adapter auf sicheren Bus)
-- MIT License © Merge Pack
local sec = require and require("railnet.lib.ccsecure.security") or dofile("/railnet/lib/ccsecure/security.lua")
local bus = require and require("railnet.lib.ccsecure.bus") or dofile("/railnet/lib/ccsecure/bus.lua")

local M = {}

function M.init()
  bus.init(sec.load_secret().key)
end

function M.publish(topic, payload)
  bus.publish(topic, payload)
end

function M.subscribe(topic, handler)
  bus.subscribe(topic, handler)
end

function M.rpc_register(method, handler, scope)
  bus.rpc_register(method, handler, scope)
end

function M.rpc_call(target_id, method, params, opts)
  return bus.rpc_call(target_id, method, params, opts)
end

return M
