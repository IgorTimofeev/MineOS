-- shared/site.lua
-- Paramètres physiques de l'installation, utilisés par l'agrégateur de situation
-- (ETA impact, risque, temps de lockdown complet). À ajuster aux coordonnées réelles en jeu.

local site = {}

site.CONFIG = {
  name = "Installation Alpha",
  center = { x = 0, y = 64, z = 0 }, -- centre du site (coordonnées monde)
  radius = 64,                        -- rayon considéré « installation » (blocs)
  lockdown = {
    perDoorSeconds = 2,               -- durée de fermeture d'une porte simple/bunker/shelter
    airlockSeconds = 3,               -- durée de cycle d'un sas
  },
}

return site
