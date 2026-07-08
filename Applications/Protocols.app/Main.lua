-- Protocols.app/Main.lua
-- Application MineOS — protocoles : lister, saisir un code et lancer en DRILL (simulation) ou RÉEL.
-- Réel = permission "protocol" (admin) ; drill = permission "drill" (agent+admin), vérifié serveur.

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. package.path

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 96, 30, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "PROTOCOLES & OVERRIDES"))

local function rpc(rtype, payload)
  payload = payload or {}; payload.token = session.token()
  return net.request(protocol.request(rtype, payload))
end

local list = window:addChild(GUI.layout(3, 8, window.width - 4, window.height - 10, 1, 1))

local function run(code, drill)
  local r = rpc(protocol.REQ.PROTOCOL_RUN, { code = code, drill = drill })
  if r and r.ok then
    GUI.alert((drill and "DRILL lancé: " or "Protocole exécuté: ") .. r.data.name)
  else
    GUI.alert("Échec: " .. tostring(r and r.error))
  end
end

local function refresh()
  list:removeChildren()
  local resp = rpc(protocol.REQ.PROTOCOL_LIST)
  if not (resp and resp.ok) then
    list:addChild(GUI.text(1, 1, 0xDD4444, "Non autorisé ou serveur injoignable."))
    workspace:draw(); return
  end
  for _, p in ipairs(resp.data.protocols) do
    local row = list:addChild(GUI.container(1, 1, list.width, 1))
    row:addChild(GUI.text(1, 1, 0xCCCCCC, string.format("%-28s code:%-6s %s", p.name, p.code, p.role)))
    if p.drillable then
      row:addChild(GUI.button(48, 1, 10, 1, 0x9E9D24, 0xFFF, 0x2D2D2D, 0xFFF, "Drill")).onTouch = function() run(p.code, true) end
    end
    row:addChild(GUI.button(60, 1, 10, 1, 0xB71C1C, 0xFFF, 0x2D2D2D, 0xFFF, "RÉEL")).onTouch = function() run(p.code, false) end
  end
  workspace:draw()
end

-- Saisie directe par code.
local codeInput = window:addChild(GUI.input(3, 5, 16, 1, 0x262626, 0x999, 0x262626, 0xFFF, 0xFFF, "", "code"))
window:addChild(GUI.button(21, 5, 12, 1, 0x9E9D24, 0xFFF, 0x2D2D2D, 0xFFF, "Drill")).onTouch = function()
  if codeInput.text ~= "" then run(codeInput.text, true) end
end
window:addChild(GUI.button(35, 5, 12, 1, 0xB71C1C, 0xFFF, 0x2D2D2D, 0xFFF, "RÉEL")).onTouch = function()
  if codeInput.text ~= "" then run(codeInput.text, false) end
end
window:addChild(GUI.button(49, 5, 14, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Rafraîchir")).onTouch = refresh

refresh()
