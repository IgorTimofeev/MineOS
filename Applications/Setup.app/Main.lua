-- Setup.app/Main.lua
-- Première configuration d'un terminal SecSite : saisir le secret réseau (le « code ») partagé
-- avec le serveur, l'enregistrer, PUIS vérifier immédiatement que le serveur répond (ping signé).

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. package.path

local GUI = require("GUI")
local system = require("System")
local paths = require("Paths")
local netsec = require("shared/netsec")
local net = require("mineos/lib/net")

local SEC_APPS = {
  "SecurityConsole", "Access", "Accounts", "Badges", "Logs", "Messages",
  "Fleet", "Protocols", "Reactor", "Defense", "Config", "Map", "Setup",
}

-- Crée un raccourci .lnk sur le bureau pour chaque app SecSite.
local function addToDesktop()
  local n = 0
  for _, a in ipairs(SEC_APPS) do
    local ok = pcall(system.createShortcut, paths.user.desktop .. a, "/Applications/" .. a .. ".app")
    if ok then n = n + 1 end
  end
  return n
end

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 70, 18, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "SECSITE — Configuration du terminal"))

window:addChild(GUI.text(3, 5, 0xAAAAAA, "Secret réseau (le même que le serveur, >= 8 caractères) :"))
local input = window:addChild(GUI.input(3, 7, 40, 3, 0x262626, 0x999999, 0x262626, 0xFFFFFF, 0xFFFFFF, "", "code"))
local status = window:addChild(GUI.text(3, 12, 0x888888, "En attente…"))

-- Écrit le secret dans un fichier lu par net.lua aux prochains lancements.
local function saveSecret(code)
  for _, path in ipairs({ "/secsite.secret", ROOT .. "/secret" }) do
    local f = io.open(path, "w")
    if f then f:write(code); f:close(); return true end
  end
  return false
end

window:addChild(GUI.button(3, 9, 24, 3, 0x2E7D32, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "Tester & enregistrer")).onTouch = function()
  local code = input.text or ""
  if #code < 8 then
    status.text = "✗ Le secret doit faire au moins 8 caractères."
    status.color = 0xDD4444
    workspace:draw(); return
  end
  netsec.setSecret(code)   -- applique immédiatement pour le test
  saveSecret(code)         -- persiste pour les prochains démarrages

  status.text = "Test du serveur…"; status.color = 0xAAAAAA; workspace:draw()
  local resp = net.ping()
  if resp and resp.ok then
    local n = addToDesktop()
    status.text = "✓ Serveur EN LIGNE (v" .. tostring(resp.data.v) .. "). " .. n .. " icônes ajoutées au bureau."
    status.color = 0x44DD44
  else
    status.text = "✗ Serveur injoignable. Vérifie : serveur allumé, MÊME code, carte réseau reliée."
    status.color = 0xDD4444
  end
  workspace:draw()
end

-- Bouton dédié : ajouter les apps au bureau sans refaire le test.
window:addChild(GUI.button(29, 9, 30, 3, 0x3C3C3C, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "Apps sur le bureau")).onTouch = function()
  local n = addToDesktop()
  status.text = n .. " icônes ajoutées au bureau. (rafraîchis le bureau)"
  status.color = 0x44DD44
  workspace:draw()
end

workspace:draw()
