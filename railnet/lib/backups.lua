local store=dofile('/railnet/lib/store.lua')
local BK = {}; BK.dir='/.railnet_backups'
local function ensure() if not fs.isDir(BK.dir) then fs.makeDir(BK.dir) end end
function BK.make(kind, snapshot) ensure(); local ts=os.date('%Y%m%d_%H%M%S'); local path=BK.dir..'/backup_'..(kind or 'manual')..'_'..ts..'.lua'; local h=fs.open(path,'w'); h.write('return '..textutils.serialize(snapshot)); h.close(); return path end
function BK.list() ensure(); local t=fs.list(BK.dir); table.sort(t,function(a,b) return a>b end); return t end
function BK.restore(fname) local f=loadfile(BK.dir..'/'..fname); return f and f() or nil end
function BK.prune(keep) ensure(); keep=keep or 10; local t=BK.list(); while #t>keep do local v=t[#t]; fs.delete(BK.dir..'/'..v); table.remove(t,#t) end end
return BK
