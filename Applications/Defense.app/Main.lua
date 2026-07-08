-- Defense.app/Main.lua
-- Application MineOS (admin) — contre-mesures anti-missile : mode off/manual/auto + tir manuel.
-- En mode auto, le serveur engage automatiquement les contre-mesures sur escalade DEFCON.

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. (package.path or "")

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 80, 24, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "CONTRE-MESURES ANTI-MISSILE"))

local function rpc(rtype, payload)
  payload = payload or {}; payload.token = session.token()
  return net.request(protocol.request(rtype, payload))
end

local modeLabel = window:addChild(GUI.text(3, 5, 0xAAAAAA, "Mode : —"))

local function refresh()
  local resp = rpc(protocol.REQ.DEFENSE_STATE)
  if resp and resp.ok then
    modeLabel.text = "Mode : " .. tostring(resp.data.mode) ..
      (resp.data.lastFire and ("   dernier tir: x" .. resp.data.lastFire.count) or "")
  else
    modeLabel.text = "Mode : (non autorisé / injoignable)"
  end
  workspace:draw()
end

local function setMode(m)
  local r = rpc(protocol.REQ.DEFENSE_MODE, { mode = m })
  if not (r and r.ok) then GUI.alert("Échec: " .. tostring(r and r.error)) end
  refresh()
end

window:addChild(GUI.button(3, 7, 14, 3, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "OFF")).onTouch = function() setMode("off") end
window:addChild(GUI.button(19, 7, 14, 3, 0x2E7D32, 0xFFF, 0x2D2D2D, 0xFFF, "MANUEL")).onTouch = function() setMode("manual") end
window:addChild(GUI.button(35, 7, 14, 3, 0xEF6C00, 0xFFF, 0x2D2D2D, 0xFFF, "AUTO")).onTouch = function() setMode("auto") end

window:addChild(GUI.button(3, 12, 30, 3, 0xB71C1C, 0xFFF, 0x2D2D2D, 0xFFF, "TIR MANUEL")).onTouch = function()
  local r = rpc(protocol.REQ.DEFENSE_FIRE)
  GUI.alert((r and r.ok) and ("Tir: x" .. r.data.fired) or ("Échec: " .. tostring(r and r.error)))
  refresh()
end

window:addChild(GUI.button(3, window.height - 1, 14, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Rafraîchir")).onTouch = refresh
refresh()
