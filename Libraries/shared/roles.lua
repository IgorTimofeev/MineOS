-- shared/roles.lua
-- Rôles et permissions. Vérifiés CÔTÉ SERVEUR (jamais faire confiance au client).
-- Une permission est une chaîne ; le suffixe "*" agit comme joker (ex. "door:*").

local roles = {}

roles.LIST = { "admin", "agent", "invite" }

roles.PERMISSIONS = {
  admin = { "*" }, -- tout
  agent = {
    "view_dashboard",
    "view_logs",
    "ack_alarm",
    "lockdown",
    "announce",     -- publier une annonce / bulletin
    "drill",        -- lancer un protocole en mode simulation
    "door:*",       -- toutes les portes de zone...
    -- (le silo reste réservé à admin : "door:silo" n'est PAS couvert, voir ci-dessous)
  },
  invite = {
    "view_dashboard",
    "door:lobby",
  },
}

-- Permissions sensibles qui exigent un rôle explicite même si un joker pourrait matcher.
-- Ex : la trappe de silo ne doit jamais tomber sous "door:*".
roles.RESTRICTED = {
  ["door:silo"] = { admin = true },
}

local function matches(pattern, perm)
  if pattern == perm then return true end
  local prefix = pattern:match("^(.-)%*$")
  if prefix then
    return perm:sub(1, #prefix) == prefix
  end
  return false
end

-- roles.can(role, permission) -> booléen
function roles.can(role, permission)
  if type(role) ~= "string" or type(permission) ~= "string" then return false end

  -- Restriction explicite : seul un rôle listé passe, joker ignoré.
  local restricted = roles.RESTRICTED[permission]
  if restricted then
    return restricted[role] == true
  end

  local perms = roles.PERMISSIONS[role]
  if not perms then return false end
  for _, p in ipairs(perms) do
    if matches(p, permission) then return true end
  end
  return false
end

function roles.isRole(role)
  return roles.PERMISSIONS[role] ~= nil
end

return roles
