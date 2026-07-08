-- shared/protocols.lua
-- Protocoles déclaratifs : séquences d'actions lançables par CODE (drill ou override réel).
-- Une step = { type=..., ... }. Types gérés par server/services/protocols.lua :
--   announce{text} · alarm{on} · lockdown · release · disable_nodes{exclude} · wait{s}
-- drillable=true : le protocole peut être joué en simulation (mode drill = non destructif).

local protocols = {}

protocols.LIST = {
  {
    id = "drill_evac", name = "Drill évacuation", code = "1111", role = "agent", drillable = true,
    steps = {
      { type = "announce", text = "DRILL: procédure d'évacuation" },
      { type = "alarm", on = true },
      { type = "wait", s = 3 },
      { type = "alarm", on = false },
    },
  },
  {
    id = "lockdown_full", name = "Confinement total", code = "2222", role = "admin", drillable = true,
    steps = {
      { type = "announce", text = "CONFINEMENT TOTAL EN COURS" },
      { type = "alarm", on = true },
      { type = "lockdown" },
    },
  },
  {
    id = "release_all", name = "Levée du confinement", code = "0000", role = "admin", drillable = false,
    steps = {
      { type = "release" },
      { type = "alarm", on = false },
      { type = "announce", text = "Fin de confinement" },
    },
  },
  {
    id = "blackout", name = "Coupure des postes (override)", code = "9999", role = "admin", drillable = false,
    steps = {
      { type = "announce", text = "OVERRIDE: coupure des postes de travail" },
      { type = "disable_nodes", exclude = "display" }, -- épargne les écrans du mur
    },
  },
  {
    id = "restore_nodes", name = "Rétablir les postes", code = "9990", role = "admin", drillable = false,
    steps = {
      { type = "restore_nodes", exclude = "display" },
      { type = "announce", text = "Postes rétablis" },
    },
  },
}

function protocols.get(idOrCode)
  for _, p in ipairs(protocols.LIST) do
    if p.id == idOrCode or p.code == idOrCode then return p end
  end
  return nil
end

return protocols
