-- shared/util.lua
-- Petits utilitaires portables (OpenComputers / Lua 5.3 standard).
-- Pas de dépendance à un composant : utilisable côté serveur, terminal, agent et en test.

local util = {}

-- Horloge : uptime monotone si dispo (OC expose `computer`), sinon os.clock.
function util.uptime()
  if type(_G.computer) == "table" and computer.uptime then
    return computer.uptime()
  end
  return os.clock()
end

-- Timestamp epoch (secondes). os.time existe sur OpenOS et en Lua standard.
function util.now()
  return os.time()
end

-- Horodatage lisible pour les logs.
function util.stamp(t)
  return os.date("!%Y-%m-%d %H:%M:%S", t or util.now())
end

-- Identifiant court (8 hex). Suffisant pour des ids internes / nonces.
local seeded = false
local function seed()
  if seeded then return end
  seeded = true
  local s = (util.now() * 1000) + math.floor((util.uptime() * 1000) % 1000000)
  math.randomseed(s)
end

function util.uuid(len)
  seed()
  len = len or 8
  local out = {}
  for i = 1, len do
    out[i] = string.format("%x", math.random(0, 15))
  end
  return table.concat(out)
end

-- Jeton de session plus long.
function util.token()
  return util.uuid(32)
end

-- Sérialisation Lua minimale (tables de string/number/boolean, imbriquées).
function util.serialize(v)
  local t = type(v)
  if t == "nil" then
    return "nil"
  elseif t == "number" or t == "boolean" then
    return tostring(v)
  elseif t == "string" then
    return string.format("%q", v)
  elseif t == "table" then
    local parts = {}
    for k, val in pairs(v) do
      local key
      if type(k) == "string" and k:match("^[%a_][%w_]*$") then
        key = k
      else
        key = "[" .. util.serialize(k) .. "]"
      end
      parts[#parts + 1] = key .. "=" .. util.serialize(val)
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  error("util.serialize: type non supporté: " .. t)
end

-- Désérialisation en environnement vide (aucun accès aux globales -> pas d'exécution).
function util.deserialize(s)
  if type(s) ~= "string" then return nil end
  local f = load("return " .. s, "=data", "t", {})
  if not f then return nil end
  local ok, res = pcall(f)
  if ok then return res end
  return nil
end

-- Copie superficielle (pratique pour renvoyer un état sans exposer la table interne).
function util.shallow(t)
  local out = {}
  for k, v in pairs(t) do out[k] = v end
  return out
end

return util
