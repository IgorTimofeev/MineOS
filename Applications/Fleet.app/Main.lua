-- Fleet.app/Main.lua
-- Application MineOS (admin) — gestion de la flotte : lister les machines et envoyer
-- reboot / shutdown / lock à distance. Commandes réservées au rôle Admin (vérifié serveur).

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. package.path

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 100, 30, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "FLOTTE — Gestion à distance"))

local function rpc(rtype, payload)
  payload = payload or {}; payload.token = session.token()
  return net.request(protocol.request(rtype, payload))
end

local list = window:addChild(GUI.layout(3, 5, window.width - 4, window.height - 7, 1, 1))

local function send(address, command)
  local r = rpc(protocol.REQ.NODE_CMD, { address = address, command = command })
  if not (r and r.ok) then GUI.alert("Échec: " .. tostring(r and r.error)) end
end

local function refresh()
  list:removeChildren()
  local resp = rpc(protocol.REQ.NODE_LIST)
  if not (resp and resp.ok) then
    list:addChild(GUI.text(1, 1, 0xDD4444, "Rôle Admin requis ou serveur injoignable."))
    workspace:draw(); return
  end
  for _, n in ipairs(resp.data.nodes) do
    local row = list:addChild(GUI.container(1, 1, list.width, 1))
    row:addChild(GUI.text(1, 1, 0xCCCCCC, string.format("%s  %-10s %s", n.address:sub(1, 8), n.kind, n.status)))
    row:addChild(GUI.button(40, 1, 12, 1, 0xEF6C00, 0xFFF, 0x2D2D2D, 0xFFF, "Reboot")).onTouch = function() send(n.address, "reboot") end
    row:addChild(GUI.button(54, 1, 12, 1, 0xB71C1C, 0xFFF, 0x2D2D2D, 0xFFF, "Éteindre")).onTouch = function() send(n.address, "shutdown") end
    row:addChild(GUI.button(68, 1, 12, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Verrouiller")).onTouch = function() send(n.address, "lock") end
  end
  workspace:draw()
end

window:addChild(GUI.button(3, window.height - 1, 14, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Rafraîchir")).onTouch = refresh
refresh()
