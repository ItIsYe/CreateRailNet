local ETA=dofile('/railnet/lib/eta.lua')
local TT={}
local function mmss(s) s=math.max(0,math.floor(s or 0)); local m=math.floor(s/60); local r=s%60; return string.format("%02d:%02d",m,r) end
function TT.build(M, now, stationFilter)
  local rows={}
  for _,svc in ipairs(M.services or {}) do
    if svc.enabled~=false and #(svc.route or {})>=2 then
      local a,b=svc.route[1],svc.route[2]; if (not stationFilter) or (stationFilter==a) then
        local head=svc.headway_sec or 300; local off=svc.offset_sec or 0
        local nextSlot= now + (head - ((now - off) % head))
        local eta=ETA.predict(a,b,head); local status='ok'
        local track=(svc.fixed_platforms and svc.fixed_platforms[a]) or ((M.stations[a] and M.stations[a].tracks and M.stations[a].tracks[1]) or 1)
        table.insert(rows,{time=os.date('%H:%M',nextSlot), ttype=svc.type or '?', line=svc.id or '?', from=a, to=b, track=track, eta=mmss(eta), status=status})
      end
    end
  end
  table.sort(rows,function(x,y) return x.time<y.time end)
  return rows
end
return TT
