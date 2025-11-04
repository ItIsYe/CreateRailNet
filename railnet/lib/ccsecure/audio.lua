-- railnet/lib/ccsecure/audio.lua  (Gong/Say Placeholder)
-- MIT License © Merge Pack
local A = {}
local sp
local function ensure() if sp and peripheral.isPresent(peripheral.getName(sp)) then return true end; sp=peripheral.find("speaker"); return sp ~= nil end
function A.gong() if not ensure() then return false end; peripheral.call(peripheral.getName(sp),"playNote","pling",3,12); sleep(0.05); peripheral.call(peripheral.getName(sp),"playNote","pling",4,15); return true end
function A.say(text) if not ensure() then return false end; for _ in (text or ""):gmatch("%S+") do peripheral.call(peripheral.getName(sp),"playNote","bit",2,10); sleep(0.02) end; return true end
return A
