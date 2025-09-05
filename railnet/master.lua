-- master.lua — v4.3.3 (Provision, Fahrplan-Vorschau, Settings)
local ui=dofile('/railnet/lib/ui.lua')
local store=dofile('/railnet/lib/store.lua')
local T=dofile('/railnet/lib/transport.lua')
local TT=dofile('/railnet/lib/timetable.lua')
local S=dofile('/railnet/lib/scheduler.lua')
local BK=dofile('/railnet/lib/backups.lua')

local M=store.load('/railnet/master.db') or {
  stations={}, services={}, routes={}, conflicts={},
  settings={ show_seconds=true, auto_bcast={enabled=false,every_sec=30}, max_backups=10 }
}
local function save() store.save('/railnet/master.db',M) end

local mon=peripheral.find('monitor') or term; if mon.setTextScale then mon.setTextScale(0.5) end
local function WH() if mon.getSize then return mon.getSize() else return term.getSize() end end
local page='Provision'; local hits={}; local scroll={plan=0,conf=0}
local function toast(s,level) local W,H=WH(); ui.line(mon,1,H-2,W,H-2,colors.gray); ui.tag(mon,2,H-1,s,(level=='E' and colors.red) or (level=='W' and colors.yellow) or colors.lime) end

local prov={ src={user='',repo='CreateRailNet',branch='main'}, target='*', role='display', label='' }

local function header()
  local W,H=WH(); ui.clear(mon)
  ui.tag(mon,2,1,'CreateRailNet v4.3.3 — Master',colors.cyan)
  ui.tag(mon,W-8,1,os.date(M.settings.show_seconds and '%H:%M:%S' or '%H:%M'),colors.lightGray)
  local tabs={'Fahrplan','Provision','SETTINGS'}
  local x=2; hits={}
  for _,t in ipairs(tabs) do hits['tab_'..t]=ui.button(mon,x,2,t,page==t); x=x+#('['..t..'] ')+1 end
end

local function drawProvision()
  header(); local y=5
  ui.tag(mon,2,y,'Provision (Remote: Quelle, Rolle, Label, Update, Reboot)',colors.cyan); y=y+1
  ui.tag(mon,2,y, 'Ziel-Label (* = alle): '..(prov.target or '*')); hits.p_tgt=ui.button(mon,34,y,'SET',false); y=y+1
  ui.tag(mon,2,y, 'Quelle GitHub: '..(prov.src.user or '')..'/'..(prov.src.repo or '')..'@'..(prov.src.branch or ''))
  hits.p_src=ui.button(mon,46,y,'SET',false); hits.p_src_push=ui.button(mon,54,y,'Quelle verteilen',false); y=y+2
  ui.tag(mon,2,y,'Rolle: '..(prov.role or '')); hits.p_role=ui.button(mon,18,y,'SET',false)
  ui.tag(mon,30,y,'Label: '..(prov.label or '')); hits.p_label=ui.button(mon,46,y,'SET',false); y=y+1
  hits.p_apply=ui.button(mon,2,y,'Rolle+Label anwenden',true)
  hits.p_update=ui.button(mon,22,y,'UPDATE',false)
  hits.p_updateF=ui.button(mon,32,y,'UPDATE --force',false)
  hits.p_reboot=ui.button(mon,50,y,'REBOOT',false)
end

local function drawPlan()
  header(); local y=5
  hits.bc_all=ui.button(mon,2,y,'BCAST alle',false); hits.bc_auto=ui.button(mon,15,y, M.settings.auto_bcast.enabled and 'Auto AUS' or 'Auto AN',false); y=y+1
  ui.tag(mon,2,y,string.format('%-5s %-2s %-8s %-4s %-4s %-4s %-6s %-8s','Zeit','T','Linie','Von','Nach','Gl','ETA','Status'), colors.white); y=y+1
  local rows=TT.build(M, os.epoch('utc')/1000, nil)
  local start=1+scroll.plan; local stop=math.min(#rows, start+12)
  for i=start,stop do local r=rows[i]; ui.tag(mon,2,y,string.format('%-5s %-2s %-8s %-4s %-4s %-4s %-6s %-8s',r.time,r.ttype,r.line,r.from,r.to,tostring(r.track),r.eta,r.status)); y=y+1 end
  hits.plan_up=ui.button(mon,2,y+1,'UP',false); hits.plan_dn=ui.button(mon,8,y+1,'DOWN',false)
end

local function drawSettings()
  header(); local y=5; ui.tag(mon,2,y,'Settings, Auto-Broadcast & Backups',colors.cyan); y=y+1
  ui.tag(mon,2,y,'Auto-Broadcast: '..(M.settings.auto_bcast.enabled and 'AN' or 'AUS')..' alle '..tostring(M.settings.auto_bcast.every_sec or 30)..'s')
  hits.set_auto=ui.button(mon,36,y, M.settings.auto_bcast.enabled and 'AUS' or 'AN',false)
  hits.set_ab_m=ui.button(mon,42,y,'-5s',false); hits.set_ab_p=ui.button(mon,48,y,'+5s',false); y=y+1
  ui.tag(mon,2,y,'Backups: max '..tostring(M.settings.max_backups or 10))
  hits.bk_make=ui.button(mon,20,y,'Backup erstellen',false)
  hits.bk_list=ui.button(mon,36,y,'Backups anzeigen',false)
  hits.bk_rest=ui.button(mon,54,y,'Neueste wiederherstellen',false); y=y+1
  ui.tag(mon,2,y,'Uhr mit Sekunden: '..(M.settings.show_seconds and 'AN' or 'AUS')); hits.set_secs=ui.button(mon,28,y,'TOGGLE',false)
end

local function draw()
  if page=='Fahrplan' then drawPlan()
  elseif page=='Provision' then drawProvision()
  elseif page=='SETTINGS' then drawSettings()
  end
end

local lastTick=os.clock(); local lastB=os.clock()
while true do
  local now=os.clock()
  if now-lastTick>0.5 then lastTick=now; S.tick(M, os.epoch('utc')/1000) end
  if M.settings.auto_bcast.enabled and (now-lastB)>(M.settings.auto_bcast.every_sec or 30) then lastB=now; local rows=TT.build(M, os.epoch('utc')/1000, nil); T.broadcast('timetable:rows',{rows=rows}) end
  draw()
  local ev={os.pullEvent()}
  if ev[1]=='monitor_touch' or ev[1]=='mouse_click' then
    local x,y=ev[3] or ev[2], ev[4] or ev[3]
    for k,b in pairs(hits) do if ui.hit(x,y,b) then
      if k:match('^tab_') then page=k:sub(5); break end
      if page=='Fahrplan' then
        if k=='bc_all' then local rows=TT.build(M, os.epoch('utc')/1000, nil); T.broadcast('timetable:rows',{rows=rows}); toast('Broadcast gesendet') break end
        if k=='bc_auto' then M.settings.auto_bcast.enabled=not M.settings.auto_bcast.enabled; save(); toast('Auto-Broadcast '..(M.settings.auto_bcast.enabled and 'AN' or 'AUS')) break end
        if k=='plan_up' then scroll.plan=math.max(0,(scroll.plan or 0)-1) break end
        if k=='plan_dn' then scroll.plan=(scroll.plan or 0)+1 break end
      elseif page=='Provision' then
        if k=='p_tgt' then term.redirect(term.native()); write('Ziel-Label (*=alle): '); prov.target=read(); term.redirect(mon); break end
        if k=='p_src' then term.redirect(term.native()); write('GitHub User: '); prov.src.user=read(); write('Repo [CreateRailNet]: '); local r=read(); prov.src.repo=(r~='' and r or 'CreateRailNet'); write('Branch [main]: '); local b=read(); prov.src.branch=(b~='' and b or 'main'); term.redirect(mon); break end
        if k=='p_src_push' then T.broadcast('provision:set_source', { GITHUB_USER=prov.src.user, REPO=prov.src.repo, BRANCH=prov.src.branch }); toast('Quelle verteilt'); break end
        if k=='p_role' then term.redirect(term.native()); write('Rolle (master/signal/display/sensor/pa): '); prov.role=read(); term.redirect(mon); break end
        if k=='p_label' then term.redirect(term.native()); write('Label: '); prov.label=read(); term.redirect(mon); break end
        if k=='p_apply' then T.broadcast('provision:set_role',{ role=prov.role, options={} }); if prov.label and prov.label~='' then T.broadcast('provision:set_label',{ label=prov.label }) end; toast('Rolle/Label angewendet'); break end
        if k=='p_update' then T.broadcast('provision:install', { force=false }); toast('Update ausgelöst'); break end
        if k=='p_updateF' then T.broadcast('provision:install', { force=true }); toast('Update --force ausgelöst'); break end
        if k=='p_reboot' then T.broadcast('provision:reboot', {}); toast('Reboot gesendet'); break end
      elseif page=='SETTINGS' then
        if k=='set_auto' then M.settings.auto_bcast.enabled=not M.settings.auto_bcast.enabled; save(); break end
        if k=='set_ab_m' then M.settings.auto_bcast.every_sec=math.max(5,(M.settings.auto_bcast.every_sec or 30)-5); save(); break end
        if k=='set_ab_p' then M.settings.auto_bcast.every_sec=(M.settings.auto_bcast.every_sec or 30)+5; save(); break end
        if k=='set_secs' then M.settings.show_seconds=not M.settings.show_seconds; save(); break end
        if k=='bk_make' then BK.make('manual', M); BK.prune(M.settings.max_backups or 10); toast('Backup erstellt'); break end
        if k=='bk_list' then local t=''; for i,f in ipairs(BK.list()) do t=t..(i>1 and ', ' or '')..f end; toast('Backups: '..t) break end
        if k=='bk_rest' then local list=BK.list(); if #list>0 then local data=BK.restore(list[1]); if type(data)=='table' then M=data; save(); toast('Backup wiederhergestellt','W') end end; break end
      end
    end end
  end
end
