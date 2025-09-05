local T=dofile('/railnet/lib/transport.lua')
local R={}
function R.canSet(M,name) return true end
function R.set(M,name,opts)
  local rt=M.routes and M.routes[name]
  if rt then
    for _,s in ipairs(rt.path or {}) do
      if s.type=='signal' or s.type=='switch' then T.broadcast('signal:set',{id=s.id,on=s.on and true or false}) end
    end
    rt.active=true; return true
  end
  return false
end
function R.release(M,name)
  local rt=M.routes and M.routes[name]
  if rt then
    for _,s in ipairs(rt.path or {}) do if s.type=='signal' then T.broadcast('signal:set',{id=s.id,on=false}) end end
    rt.active=false
  end
  return true
end
function R.processQueue(M) end
return R
