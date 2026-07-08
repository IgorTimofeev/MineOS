-- Access.app/Main.lua
-- Application MineOS — contrôle des portes typées + LOCKDOWN.
-- UI par type : simple/bunker/shelter -> Ouvrir/Fermer ; airlock -> battants Intérieur/Extérieur ;
-- silo -> armement (réservé admin côté serveur). Toutes les actions passent par le serveur (RPC signé).

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. package.path

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 96, 30, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "CONTRÔLE D'ACCÈS"))

local list = window:addChild(GUI.layout(3, 5, window.width - 4, window.height - 8, 1, 1))

local function cmd(id, action)
  local resp = net.request(protocol.request(protocol.REQ.DOOR_CMD,
    { token = session.token(), id = id, action = action }))
  if not (resp and resp.ok) then
    GUI.alert("Échec: " .. tostring(resp and resp.error or "réseau"))
  end
end

local function refresh()
  list:removeChildren()
  local resp = net.request(protocol.request(protocol.REQ.DOOR_LIST, { token = session.token() }))
  if not (resp and resp.ok) then
    list:addChild(GUI.text(1, 1, 0xDD4444, "Serveur injoignable ou non autorisé"))
    workspace:draw(); return
  end
  if resp.data.locked then
    list:addChild(GUI.text(1, 1, 0xDD4444, "⚠ LOCKDOWN ACTIF"))
  end
  for _, d in ipairs(resp.data.doors) do
    local row = list:addChild(GUI.container(1, 1, list.width, 3))
    row:addChild(GUI.text(1, 2, 0xCCCCCC, d.name .. " [" .. d.type .. "]"))
    if d.type == "airlock" then
      row:addChild(GUI.button(40, 1, 14, 3, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Intérieur")).onTouch = function()
        cmd(d.id, "inner_open")
      end
      row:addChild(GUI.button(56, 1, 14, 3, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Extérieur")).onTouch = function()
        cmd(d.id, "outer_open")
      end
    else
      row:addChild(GUI.button(40, 1, 12, 3, 0x2E7D32, 0xFFF, 0x2D2D2D, 0xFFF, "Ouvrir")).onTouch = function()
        cmd(d.id, "open")
      end
      row:addChild(GUI.button(54, 1, 12, 3, 0xB71C1C, 0xFFF, 0x2D2D2D, 0xFFF, "Fermer")).onTouch = function()
        cmd(d.id, "close")
      end
    end
  end
  workspace:draw()
end

window:addChild(GUI.button(3, window.height - 2, 18, 1, 0xB71C1C, 0xFFF, 0x2D2D2D, 0xFFF, "LOCKDOWN")).onTouch = function()
  cmd(nil, "lockdown"); refresh()
end
window:addChild(GUI.button(23, window.height - 2, 18, 1, 0x2E7D32, 0xFFF, 0x2D2D2D, 0xFFF, "Lever lockdown")).onTouch = function()
  cmd(nil, "release"); refresh()
end
window:addChild(GUI.button(43, window.height - 2, 14, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Rafraîchir")).onTouch = refresh

refresh()
