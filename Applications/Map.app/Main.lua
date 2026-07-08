-- Map.app/Main.lua
-- Application MineOS — carte 2D (vue du dessus) des contacts radar autour de l'installation.
-- Le centre/rayon viennent de shared/site.lua ; les contacts (x,z) de SITUATION_GET
-- (nécessite le radar OC HBM pour des positions ; en repli redstone, pas de blips).

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. (package.path or "")

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")
local site = require("shared/site")

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 92, 30, 0x0A0A0A))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "CARTE TACTIQUE"))

local MAP_X, MAP_Y, MAP_W, MAP_H = 3, 5, 60, 22
local mapArea = window:addChild(GUI.panel(MAP_X, MAP_Y, MAP_W, MAP_H, 0x111111))
local markers = window:addChild(GUI.container(MAP_X, MAP_Y, MAP_W, MAP_H))
local sidebar = window:addChild(GUI.layout(MAP_X + MAP_W + 2, MAP_Y, window.width - MAP_W - MAP_X - 3, MAP_H, 1, 1))

local function rpc(rtype, payload)
  payload = payload or {}; payload.token = session.token()
  return net.request(protocol.request(rtype, payload))
end

local function refresh()
  markers:removeChildren()
  sidebar:removeChildren()

  local cx, cz = site.CONFIG.center.x, site.CONFIG.center.z
  local range = math.max(16, (site.CONFIG.radius or 64) * 3) -- portée affichée
  local mcx, mcy = math.floor(MAP_W / 2), math.floor(MAP_H / 2)
  local sx, sy = mcx / range, mcy / range

  -- Centre du site.
  markers:addChild(GUI.text(mcx, mcy, 0x2E7D32, "◉"))

  local resp = rpc(protocol.REQ.SITUATION_GET)
  if not (resp and resp.ok) then
    sidebar:addChild(GUI.text(1, 1, 0xDD4444, "Injoignable / non autorisé"))
    workspace:draw(); return
  end
  local sit = resp.data

  sidebar:addChild(GUI.text(1, 1, 0xFFFFFF, "DEFCON " .. tostring(sit.defcon)))
  sidebar:addChild(GUI.text(1, 1, sit.alert and 0xEF5350 or 0x9E9E9E, sit.alert and "ALERTE" or "calme"))
  sidebar:addChild(GUI.text(1, 1, 0x9E9E9E, "Contacts: " .. tostring(sit.contacts or 0)))
  if sit.impactETA then sidebar:addChild(GUI.text(1, 1, 0xF9A825, "ETA ~" .. math.floor(sit.impactETA) .. "s")) end

  -- Blips des contacts (positions relatives au centre).
  local rc = resp.data and select(2, pcall(function() return rpc(protocol.REQ.RADAR_STATE) end))
  local radar = rc and rc.ok and rc.data or nil
  for _, k in ipairs((radar and radar.contacts) or {}) do
    if k.x and k.z then
      local mx = math.floor(mcx + (k.x - cx) * sx)
      local my = math.floor(mcy + (k.z - cz) * sy)
      if mx >= 1 and mx <= MAP_W and my >= 1 and my <= MAP_H then
        markers:addChild(GUI.text(mx, my, 0xB71C1C, "▲"))
      end
    end
  end

  -- Portes importantes en légende.
  sidebar:addChild(GUI.text(1, 1, 0x666666, "— Portes —"))
  for _, d in ipairs(sit.importantDoors or {}) do
    local st = d.state or {}
    local open = st.open or st.inner or st.outer
    sidebar:addChild(GUI.text(1, 1, open and 0xEF5350 or 0x66BB6A, (open and "▮ " or "▯ ") .. d.name))
  end
  workspace:draw()
end

window:addChild(GUI.button(3, window.height - 1, 14, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Rafraîchir")).onTouch = refresh
refresh()
