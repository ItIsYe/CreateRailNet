local store=dofile('/railnet/lib/store.lua')
local ETA=store.load('/railnet/eta.db') or {legs={}}
local function key(a,b) return tostring(a)..'>'..tostring(b) end
function ETA.update(a,b,secs) if not (a and b and secs) then return end; local k=key(a,b); local L=ETA.legs[k] or {avg_secs=secs}; L.avg_secs = 0.2*secs + 0.8*(L.avg_secs or secs); ETA.legs[k]=L; store.save('/railnet/eta.db',ETA) end
function ETA.predict(a,b,plan) local L=ETA.legs[key(a,b)]; return math.floor(L and L.avg_secs or plan) end
return ETA
