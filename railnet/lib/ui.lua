local ui = {}
local function termOrMonitor()
  if peripheral and peripheral.find then
    local mon = peripheral.find("monitor")
    if mon then mon.setTextScale(0.5); return mon end
  end
  return term
end

function ui.clear(t) t=t or termOrMonitor(); t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.clear(); t.setCursorPos(1,1) end
function ui.tag(t,x,y,s,col) t=t or termOrMonitor(); if col then t.setTextColor(col) end; t.setCursorPos(x,y); t.write(s); t.setTextColor(colors.white) end
function ui.button(t,x,y,label,active) t=t or termOrMonitor(); local s='['..label..']'; if active then t.setTextColor(colors.yellow) end; t.setCursorPos(x,y); t.write(s); t.setTextColor(colors.white); return {x=x,y=w or #s,h=1} end
-- fix width
function ui.button(t,x,y,label,active) t=t or termOrMonitor(); local s='['..label..']'; if active then t.setTextColor(colors.yellow) end; t.setCursorPos(x,y); t.write(s); t.setTextColor(colors.white); return {x=x,y=y,w=#s,h=1} end
function ui.hit(px,py,b) return b and px>=b.x and px<=b.x+b.w-1 and py==b.y end
function ui.line(t,x1,y,x2,_,col) t=t or termOrMonitor(); if col then t.setTextColor(col) end; t.setCursorPos(x1,y); t.write(string.rep('─', math.max(0,x2-x1+1))); t.setTextColor(colors.white) end
function ui.progress(t,x,y,p) t=t or termOrMonitor(); local w=20; local f=math.floor(w*math.max(0,math.min(1,p or 0))); t.setCursorPos(x,y); t.write('['..string.rep('#',f)..string.rep(' ',w-f)..']') end

return ui
