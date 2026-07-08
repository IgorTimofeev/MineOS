-- mineos/lib/blackout.lua
-- Watcher « poste inaccessible » : quand l'agent a reçu la commande `blackout`, un drapeau existe ;
-- ce module affiche alors une page plein écran bloquante jusqu'à la levée (`release`).
-- À appeler depuis le hook de login/kiosque du terminal (les écrans du mur en sont exemptés).

local component = require("component")

local blackout = {}

local FLAG = "/tmp/secsite.blackout"

function blackout.active()
  local f = io.open(FLAG, "r")
  if f then f:close(); return true end
  return false
end

function blackout.screen()
  if not component.isAvailable("gpu") then return end
  local gpu = component.gpu
  local w, h = gpu.getResolution()
  gpu.setBackground(0x330000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, w, h, " ")
  local msg = "ORDINATEUR INACCESSIBLE"
  local sub = "Acces suspendu par la securite"
  gpu.set(math.max(1, math.floor((w - #msg) / 2)), math.floor(h / 2), msg)
  gpu.set(math.max(1, math.floor((w - #sub) / 2)), math.floor(h / 2) + 2, sub)
end

-- Boucle bloquante tant que le poste est verrouillé.
function blackout.guard()
  local event = require("event")
  while blackout.active() do
    blackout.screen()
    event.pull(1)
  end
end

-- À appeler depuis la boucle de login/kiosque : prend l'écran si le poste est en blackout.
-- Renvoie true si le blackout a été appliqué (et vient d'être levé), false sinon.
function blackout.enforce()
  if blackout.active() then
    blackout.guard()
    return true
  end
  return false
end

return blackout
