-- mineos/lib/card.lua
-- Adaptateur lecteur de carte OpenSecurity (magnétique ou RFID).
-- API confirmées (wiki PC-Logix/OpenSecurity) :
--   * Magreader : événement `magData` = (address, playerName, cardData, cardUniqueId, isCardLocked, side)
--                 -> identifiant de badge = cardData (repli cardUniqueId). Passif (swipe joueur).
--   * RFID      : `scan([1-64])` déclenche `rfidData` = (uuid, playerName, distance, data)
--                 -> identifiant = data. ACTIF : il faut appeler scan().

local component = require("component")
local computer = require("computer")
local event = require("event")

local card = {}

card.EVENTS = { magData = true, rfidData = true }

-- Détecte un lecteur disponible. Renvoie (proxy, type) ou nil.
function card.reader()
  if component.isAvailable("os_magreader") then return component.os_magreader, "mag" end
  if component.isAvailable("os_rfidreader") then return component.os_rfidreader, "rfid" end
  return nil
end

function card.available()
  return card.reader() ~= nil
end

-- Extrait l'identifiant de badge selon l'événement OpenSecurity.
-- ev[1] = nom de l'événement ; les champs suivants dépendent du type.
local function extract(ev)
  local name = ev[1]
  if name == "magData" then
    -- magData: address, playerName, cardData, cardUniqueId, isCardLocked, side
    return ev[4] or ev[5]
  elseif name == "rfidData" then
    -- rfidData: uuid, playerName, distance, data
    return ev[5]
  end
  return nil
end

-- Attend une carte. Renvoie le cardId (string) ou nil au timeout.
-- Pour un lecteur RFID, on déclenche activement un scan à chaque itération.
function card.await(timeout)
  local reader, kind = card.reader()
  local deadline = timeout and (computer.uptime() + timeout) or nil
  while true do
    local remaining = deadline and (deadline - computer.uptime()) or nil
    if remaining and remaining <= 0 then return nil end
    if kind == "rfid" and reader then pcall(reader.scan) end
    -- RFID : scans rapprochés ; borne l'attente pour re-scanner régulièrement.
    local wait = remaining
    if kind == "rfid" then wait = math.min(remaining or 1, 1) end
    local ev = { event.pull(wait) }
    local name = ev[1]
    if name and card.EVENTS[name] then
      local id = extract(ev)
      if id and id ~= "" then return id end
    elseif name == nil and kind ~= "rfid" then
      return nil
    end
  end
end

return card
