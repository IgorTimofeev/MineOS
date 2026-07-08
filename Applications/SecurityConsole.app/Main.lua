-- SecurityConsole.app/Main.lua
-- Application MineOS — coquille du tableau de bord de sécurité (lot 1).
-- Utilise le framework GUI de MineOS (workspaces / conteneurs / widgets).
-- Les widgets DEFCON / portes / alertes seront ajoutés au lot 2.

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. package.path

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")

-- Couleur d'affichage selon le niveau DEFCON (5 calme -> 1 imminent).
local DEFCON_COLOR = { [5] = 0x2E7D32, [4] = 0x9E9D24, [3] = 0xF9A825, [2] = 0xEF6C00, [1] = 0xB71C1C }

-- Fenêtre principale.
local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 88, 26, 0x1E1E1E))

window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "SECURITY CONSOLE — Intranet"))

local statusLabel = window:addChild(GUI.text(3, 5, 0xAAAAAA, "Serveur : vérification…"))
local defconPanel = window:addChild(GUI.panel(3, 7, 40, 3, 0x333333))
local defconLabel = window:addChild(GUI.text(5, 8, 0xFFFFFF, "DEFCON : —"))

-- Interroge serveur (ping) + état radar (DEFCON).
local function refresh()
  local resp = net.ping()
  if resp and resp.ok then
    statusLabel.text = "Serveur : EN LIGNE (protocole v" .. tostring(resp.data.v) .. ")"
    statusLabel.color = 0x44DD44
  else
    statusLabel.text = "Serveur : INJOIGNABLE"
    statusLabel.color = 0xDD4444
  end

  local rs = net.request(protocol.request(protocol.REQ.RADAR_STATE, { token = session.token() }))
  if rs and rs.ok then
    local d = rs.data.defcon or 5
    defconLabel.text = "DEFCON : " .. d .. (rs.data.alert and "  ⚠ ALERTE" or "")
    defconPanel.color = DEFCON_COLOR[d] or 0x333333
  end
  workspace:draw()
end

window:addChild(GUI.button(3, 11, 24, 3, 0x3C3C3C, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "Rafraîchir")).onTouch = function()
  refresh()
end

-- Saisie rapide d'un code de protocole (drill/réel).
window:addChild(GUI.text(3, 16, 0xAAAAAA, "Code protocole :"))
local codeInput = window:addChild(GUI.input(19, 16, 12, 1, 0x262626, 0x999999, 0x262626, 0xFFFFFF, 0xFFFFFF, "", "code"))
local function runProto(drill)
  if codeInput.text == "" then return end
  local r = net.request(protocol.request(protocol.REQ.PROTOCOL_RUN, { token = session.token(), code = codeInput.text, drill = drill }))
  GUI.alert((r and r.ok) and ((drill and "DRILL: " or "Exécuté: ") .. r.data.name) or ("Échec: " .. tostring(r and r.error)))
end
window:addChild(GUI.button(33, 16, 10, 1, 0x9E9D24, 0xFFF, 0x2D2D2D, 0xFFF, "Drill")).onTouch = function() runProto(true) end
window:addChild(GUI.button(45, 16, 10, 1, 0xB71C1C, 0xFFF, 0x2D2D2D, 0xFFF, "RÉEL")).onTouch = function() runProto(false) end

refresh()
workspace:draw()
