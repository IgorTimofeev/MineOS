-- mineos/lib/session.lua
-- Détient la session courante du terminal (token/rôle/nom), établie par le login forké
-- (mineos/login-fork) et lue par les applications de sécurité.

local session = {}

local current = nil

function session.set(s)
  current = s -- { token, name, role }
end

function session.clear()
  current = nil
end

function session.get()
  return current
end

function session.token()
  return current and current.token or nil
end

function session.role()
  return current and current.role or nil
end

function session.name()
  return current and current.name or nil
end

return session
