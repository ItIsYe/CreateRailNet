-- railnet/slave_obis.lua  (Onboard-Infosystem – Zugdisplay)
-- MIT License © Merge Pack
local transport = require and require("railnet.lib.transport") or dofile("/railnet/lib/transport.lua")
local audio = require and require("railnet.lib.ccsecure.audio") or dofile("/railnet/lib/ccsecure/audio.lua")

local cfg = (function() if fs.exists("/railnet/device_config.lua") then local f=loadfile("/railnet/device_config.lua"); return f() end return { transport="ccsecure" } end)()

if cfg.transport=="ccsecure" then transport = require and require("railnet.lib.transport_ccsecure") or dofile("/railnet/lib/transport_ccsecure.lua") end

transport.init()

local train_id = cfg.train_id or ("T:"..os.getComputerID())
local next_stop = { name = "HBF", eta = "--:--" }
local following = {}

local function draw()
  term.setBackgroundColor(colors.black) term.setTextColor(colors.white)
  term.clear() term.setCursorPos(1,1)
  print("OBIS – Zug "..train_id)
  print("Nächster Halt: "..(next_stop.name or "?").."  → "..(next_stop.eta or "--:--"))
  print("Danach:")
  for i,s in ipairs(following) do print("  • "..(s.name or "?").." ("..(s.eta or "--:--")..")") end
  term.setCursorPos(1, 9); print("[Q] Quit  [G] Gong  [A] Ansage")
end

transport.subscribe("obis/update", function(p)
  if not p or p.train_id ~= train_id then return end
  next_stop = p.next_stop or next_stop
  following = p.following or following
  draw()
end)

transport.subscribe("ann/trigger", function(p)
  if p and p.scope=="train" and p.train_id==train_id then audio.gong(); audio.say(p.text or "") end
end)

draw()
while true do local e,k=os.pullEvent(); if e=="key" and k==keys.q then break end; if e=="key" and k==keys.g then audio.gong() end; if e=="key" and k==keys.a then audio.gong(); audio.say("Nächster Halt Test") end end
