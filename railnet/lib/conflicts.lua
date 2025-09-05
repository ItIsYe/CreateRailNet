local store=dofile('/railnet/lib/store.lua')
local C={}
function C.add(M, code, msg, level)
  M.conflicts=M.conflicts or {}
  table.insert(M.conflicts,1,{ts=os.date('%H:%M:%S'),code=code,msg=msg,level=level or 'E'})
  while #M.conflicts>150 do table.remove(M.conflicts) end
  store.save('/railnet/master.db', M)
end
return C
