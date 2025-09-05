local M = {}

local function atomicWrite(path, text)
  local tmp = path .. ".tmp"
  local h = fs.open(tmp, "w"); if not h then return false end
  h.write(text); h.close()
  if fs.exists(path) then fs.delete(path) end
  fs.move(tmp, path); return true
end

function M.save(path, tbl)
  local ok, ser = pcall(textutils.serialize, tbl); if not ok then return false end
  return atomicWrite(path, "return "..ser)
end

function M.load(path)
  if not fs.exists(path) then return nil end
  local ok,res = pcall(function() local f=loadfile(path); return f and f() end)
  return ok and res or nil
end

return M
