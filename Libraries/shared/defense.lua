-- shared/defense.lua
-- Emplacements de contre-mesures anti-missile (CIWS, silo intercepteur…).
-- Actionnés en redstone (tourelle/CIWS) ou via composant (silo HBM launch). Mode par défaut au boot.

local defense = {}

defense.DEFAULT_MODE = "manual" -- "off" | "manual" | "auto"
defense.ENGAGE_LEVEL = 2         -- en mode auto : engage si DEFCON <= ce niveau

defense.EMPLACEMENTS = {
  {
    id = "ciws_1", name = "CIWS Nord", kind = "redstone",
    side = "up", channel = 6, -- impulsion redstone d'activation
  },
  {
    id = "interceptor_1", name = "Silo intercepteur", kind = "component",
    address = "REPLACE_WITH_HBM_SILO_ADDRESS", -- composant hbm_silo (launch)
  },
}

return defense
