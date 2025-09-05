local CL = {}
function CL.compute(M)
  local function any(tbl) return (tbl and next(tbl)~=nil) end
  return {
    { key='stations', label='Stationen einrichten', done=any(M.stations) },
    { key='services', label='Dienste anlegen', done=any(M.services) },
    { key='routes',   label='Fahrstraßen anlegen', done=any(M.routes) },
    { key='display',  label='Displays installieren', done=true },
    { key='plan',     label='Fahrplan starten', done=true },
  }
end
return CL
