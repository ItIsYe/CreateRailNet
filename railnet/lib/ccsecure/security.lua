-- railnet/lib/ccsecure/security.lua  (RBAC, Secrets, Nonce Cache)
-- MIT License © Merge Pack
local S = {}
local SECRET_PATH = "/railnet/etc/secret.json"
local RBAC_PATH   = "/railnet/etc/rbac.json"
local NONCE_DB    = "/railnet/var/nonce.db"

local secret, rbac
local nonce_cache = {}
local NONCE_TTL_MS = 60000

local function read_json(path)
  if not fs.exists(path) then return nil end
  local h=fs.open(path,"r"); local s=h.readAll(); h.close(); return textutils.unserializeJSON(s)
end
local function write_json(path, tbl)
  fs.makeDir(fs.getDir(path))
  local h=fs.open(path,"w"); h.write(textutils.serializeJSON(tbl,true)); h.close()
end

local function load_nonce_cache()
  if not fs.exists(NONCE_DB) then return end
  local h=fs.open(NONCE_DB, "r")
  while true do local line=h.readLine(); if not line then break end; local tx,ts=line:match("([^|]+)|(%d+)"); if tx then nonce_cache[tx]=tonumber(ts) end end
  h.close()
end
local function trim_nonce_cache()
  local now=os.epoch("utc"); local out={}
  for tx,ts in pairs(nonce_cache) do if now-ts<NONCE_TTL_MS then out[#out+1]=tx.."|"..ts end end
  local h=fs.open(NONCE_DB,"w"); for _,ln in ipairs(out) do h.write(ln.."\n") end; h.close()
end

function S.load_secret()
  secret = secret or read_json(SECRET_PATH) or { key = "dev" }
  return secret
end
function S.set_secret(key) secret={key=key}; write_json(SECRET_PATH, secret) end

function S.load_rbac()
  rbac = rbac or read_json(RBAC_PATH) or { roles={ admin={scopes={"*"}}, dispatcher={scopes={"route:*","mode:*"}}, viewer={scopes={"read:*"}} }, users={ default={roles={"admin"}} } }
  return rbac
end
local current = { name="default", roles={"admin"} }
function S.login(name) local r=S.load_rbac(); if r.users[name] then current={name=name,roles=r.users[name].roles}; return true end return false end
function S.user() return current end

local function scope_match(scope, rule)
  if rule=="*" then return true end
  local function split(s) local t={} for p in s:gmatch("[^:]+") do t[#t+1]=p end return t end
  local s=split(scope); local r=split(rule)
  for i=1,math.max(#s,#r) do local sv,rv=s[i],r[i]; if rv=="*" then return true end; if not rv or not sv or rv~=sv then return false end end
  return true
end
function S.allow(scope)
  local r=S.load_rbac(); for _,role in ipairs(current.roles) do local rr=r.roles[role]; if rr then for _,rule in ipairs(rr.scopes or {}) do if scope_match(scope, rule) then return true end end end end
  return false
end

function S.nonce_seen(txid)
  if not txid then return false end
  local now=os.epoch("utc"); if nonce_cache[txid] and now-nonce_cache[txid] < NONCE_TTL_MS then return true end
  nonce_cache[txid]=now; trim_nonce_cache(); return false
end

load_nonce_cache(); S.load_secret(); S.load_rbac()
return S
