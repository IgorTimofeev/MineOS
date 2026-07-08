-- Config.app/Main.lua
-- Application MineOS (admin) — édite en jeu les réglages runtime (site, radar, défense),
-- appliqués à chaud côté serveur, sans toucher aux fichiers de code.

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. package.path

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 90, 28, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "CONFIGURATION (runtime)"))

local function rpc(rtype, payload)
  payload = payload or {}; payload.token = session.token()
  return net.request(protocol.request(rtype, payload))
end

local list = window:addChild(GUI.layout(3, 5, window.width - 4, window.height - 6, 1, 1))

local function refresh()
  list:removeChildren()
  local resp = rpc(protocol.REQ.SETTINGS_GET)
  if not (resp and resp.ok) then
    list:addChild(GUI.text(1, 1, 0xDD4444, "Rôle admin requis ou serveur injoignable."))
    workspace:draw(); return
  end
  for _, setting in ipairs(resp.data.settings) do
    local row = list:addChild(GUI.container(1, 1, list.width, 1))
    row:addChild(GUI.text(1, 1, 0xCCCCCC, string.format("%-24s (%s)", setting.key, setting.type)))
    local input = row:addChild(GUI.input(40, 1, 22, 1, 0x262626, 0x999, 0x262626, 0xFFF, 0xFFF,
      setting.value ~= nil and tostring(setting.value) or "", "valeur"))
    row:addChild(GUI.button(64, 1, 12, 1, 0x2E7D32, 0xFFF, 0x2D2D2D, 0xFFF, "Appliquer")).onTouch = function()
      local r = rpc(protocol.REQ.SETTINGS_SET, { key = setting.key, value = input.text })
      if not (r and r.ok) then GUI.alert("Échec: " .. tostring(r and r.error)) else refresh() end
    end
  end
  workspace:draw()
end

window:addChild(GUI.button(3, window.height - 1, 14, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Rafraîchir")).onTouch = refresh
refresh()
