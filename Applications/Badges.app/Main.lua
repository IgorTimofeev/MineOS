-- Badges.app/Main.lua
-- Application MineOS (admin) — émission/révocation de badges.
-- Émettre : génère un cardId, le GRAVE sur la carte physique (os_cardwriter) et l'associe au
-- compte côté serveur (ACCOUNT_SETCARD). Révoquer : détache la carte du compte.

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. (package.path or "")

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local writer = require("mineos/lib/writer")
local protocol = require("shared/protocol")

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 96, 30, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "ÉMISSION DE BADGES"))

local status = window:addChild(GUI.text(3, 5, 0xAAAAAA,
  writer.available() and "Graveur détecté." or "⚠ Aucun graveur (os_cardwriter)."))

local function rpc(rtype, payload)
  payload = payload or {}
  payload.token = session.token()
  return net.request(protocol.request(rtype, payload))
end

local list = window:addChild(GUI.layout(3, 7, window.width - 4, window.height - 9, 1, 1))

local function issue(acc)
  local cardId = writer.newCardId()
  local okWrite, wReason = writer.write(cardId, "SecSite: " .. acc.name)
  if not okWrite then
    GUI.alert("Gravure impossible: " .. tostring(wReason)); return
  end
  local resp = rpc(protocol.REQ.ACCOUNT_SETCARD, { id = acc.id, cardId = cardId })
  if resp and resp.ok then status.text = "Badge émis pour " .. acc.name
  else GUI.alert("Enregistrement échoué: " .. tostring(resp and resp.error)) end
  workspace:draw()
end

local function revoke(acc)
  local resp = rpc(protocol.REQ.ACCOUNT_SETCARD, { id = acc.id }) -- cardId nil = révocation
  if resp and resp.ok then status.text = "Badge révoqué pour " .. acc.name end
  workspace:draw()
end

local function refresh()
  list:removeChildren()
  local resp = rpc(protocol.REQ.ACCOUNT_LIST)
  if not (resp and resp.ok) then
    list:addChild(GUI.text(1, 1, 0xDD4444, "Non autorisé.")); workspace:draw(); return
  end
  for _, a in ipairs(resp.data.accounts) do
    local row = list:addChild(GUI.container(1, 1, list.width, 1))
    row:addChild(GUI.text(1, 1, 0xCCCCCC, string.format("%-16s %s", a.name, a.hasCard and "🪪 badge" or "—")))
    row:addChild(GUI.button(40, 1, 14, 1, 0x2E7D32, 0xFFF, 0x2D2D2D, 0xFFF, "Émettre")).onTouch = function() issue(a) end
    row:addChild(GUI.button(56, 1, 14, 1, 0xB71C1C, 0xFFF, 0x2D2D2D, 0xFFF, "Révoquer")).onTouch = function() revoke(a) end
  end
  workspace:draw()
end

refresh()
