-- mineos/lib/writer.lua
-- Adaptateur du graveur de carte OpenSecurity (os_cardwriter) pour l'émission de badges.
-- La signature exacte de write(...) est À CONFIRMER en jeu ; isolée ici.

local component = require("component")
local util = require("shared/util")

local writer = {}

function writer.available()
  return component.isAvailable("os_cardwriter")
end

-- Génère un identifiant de badge unique.
function writer.newCardId()
  return "SEC-" .. util.uuid(24)
end

-- Grave un cardId sur la carte physique posée dans le graveur.
-- Renvoie true, ou (nil, raison).
function writer.write(cardId, label)
  if not writer.available() then return nil, "no_writer" end
  local w = component.os_cardwriter
  local ok = pcall(function()
    -- Ordre des arguments probable : (data, label, isRewritable) — à ajuster une fois testé.
    w.write(cardId, label or "SecSite Badge", true)
  end)
  if not ok then return nil, "write_failed" end
  return true
end

return writer
