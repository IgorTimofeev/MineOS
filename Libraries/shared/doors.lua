-- shared/doors.lua
-- Configuration DÉCLARATIVE des portes de l'installation.
-- Ajouter une porte = ajouter une entrée ici (aucun code à écrire).
-- Le moteur de portes (server/services/doors.lua, lot 2) interprète `type` et `driver`.
--
-- driver.kind :
--   "redstone"  -> contrôleur HBM / porte blast / trappe silo, via redstone
--                  (side + éventuellement channel bundled Project Red)
--   "os_secdoor"-> composant OpenSecurity adressé (address)
-- type : "simple" | "bunker" | "shelter" | "airlock" | "silo"

local doors = {}

doors.CONFIG = {
  {
    id = "lobby",
    name = "Porte d'accueil",
    type = "simple",
    zone = "lobby",
    roles = { "admin", "agent", "invite" },
    driver = { kind = "os_secdoor", address = "REPLACE_WITH_SECDOOR_ADDRESS" },
  },
  {
    id = "bunker_main",
    name = "Entrée bunker",
    type = "bunker",
    zone = "A",
    roles = { "admin", "agent" },
    driver = { kind = "redstone", side = "north", channel = 1 },
  },
  {
    id = "airlock_A",
    name = "Sas arrivée/sortie A",
    type = "airlock",
    zone = "A",
    roles = { "admin", "agent" },
    -- Deux battants interverrouillés : un canal par battant.
    driver = { kind = "redstone", side = "north", channelInner = 2, channelOuter = 3 },
    cycleSeconds = 3, -- délai de sécurité entre battants
  },
  {
    id = "shelter_1",
    name = "Porte abri",
    type = "shelter",
    zone = "B",
    roles = { "admin", "agent" },
    driver = { kind = "redstone", side = "up", channel = 4 },
  },
  {
    id = "silo_hatch",
    name = "Trappe silo",
    type = "silo",
    zone = "silo",
    roles = { "admin" }, -- + permission restreinte "door:silo"
    driver = { kind = "redstone", side = "south", channel = 5 },
  },
  {
    id = "bunker_oc",
    name = "Porte bunker (via addon OC HBM)",
    type = "bunker",
    zone = "A",
    roles = { "admin", "agent" },
    -- Pilotage direct par composant HBM exposé par hbm-oc-addon (au lieu du redstone).
    driver = { kind = "hbm_oc", address = "REPLACE_WITH_HBM_DOOR_ADDRESS" },
  },
}

function doors.get(id)
  for _, d in ipairs(doors.CONFIG) do
    if d.id == id then return d end
  end
  return nil
end

-- Permission associée à une porte (ex. "door:A", "door:silo").
function doors.permission(door)
  if door.type == "silo" then return "door:silo" end
  return "door:" .. (door.zone or door.id)
end

return doors
