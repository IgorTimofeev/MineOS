-- Messages.app/Main.lua
-- Application MineOS — collaboration : bulletin d'annonces + boîte de réception.
-- Publier une annonce la diffuse à tous les terminaux et dans le chat du serveur (Computronics).

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. (package.path or "")

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 100, 32, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "MESSAGERIE & ANNONCES"))

local function rpc(rtype, payload)
  payload = payload or {}; payload.token = session.token()
  return net.request(protocol.request(rtype, payload))
end

window:addChild(GUI.text(3, 5, 0xAAAAAA, "Tableau d'annonces"))
local board = window:addChild(GUI.textBox(3, 6, window.width - 4, 10, 0x161616, 0xBBBBBB, {}, 1, 0, 0))

window:addChild(GUI.text(3, 18, 0xAAAAAA, "Boîte de réception"))
local inbox = window:addChild(GUI.textBox(3, 19, window.width - 4, 8, 0x161616, 0xBBBBBB, {}, 1, 0, 0))

local function refresh()
  local b = rpc(protocol.REQ.BOARD_GET, { limit = 20 })
  local blines = {}
  if b and b.ok then
    for _, a in ipairs(b.data.board) do blines[#blines + 1] = (a.stamp or "") .. "  " .. a.actor .. ": " .. a.text end
  end
  board.lines = #blines > 0 and blines or { "(aucune annonce)" }

  local m = rpc(protocol.REQ.MSG_INBOX)
  local mlines = {}
  if m and m.ok then
    for _, e in ipairs(m.data.messages) do mlines[#mlines + 1] = (e.stamp or "") .. "  " .. e.from .. ": " .. e.text end
  end
  inbox.lines = #mlines > 0 and mlines or { "(aucun message)" }
  workspace:draw()
end

-- Zone de publication d'annonce.
local annInput = window:addChild(GUI.input(3, window.height - 2, 60, 1, 0x262626, 0x999, 0x262626, 0xFFF, 0xFFF, "", "annonce…"))
window:addChild(GUI.button(65, window.height - 2, 14, 1, 0x2E7D32, 0xFFF, 0x2D2D2D, 0xFFF, "Publier")).onTouch = function()
  if annInput.text ~= "" then
    rpc(protocol.REQ.ANNOUNCE_POST, { text = annInput.text })
    annInput.text = ""
    refresh()
  end
end
window:addChild(GUI.button(81, window.height - 2, 14, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Rafraîchir")).onTouch = refresh

refresh()
