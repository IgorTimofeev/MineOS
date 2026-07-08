-- update.lua — Met à jour les fichiers SecSite sur une installation MineOS existante :
-- re-télécharge libs + apps depuis ce dépôt et pose les icônes sur le bureau.
-- À lancer depuis Lua.app (voir le bootstrapper court fourni).

local component = require("component")
local fs = require("Filesystem")
local system = require("System")
local paths = require("Paths")

local BASE = "https://raw.githubusercontent.com/quentinthierry12/mineos/master/"
local inet = component.internet

local function download(path)
  local h = inet.request(BASE .. path)
  local deadline = require("computer").uptime() + 10
  while true do
    local ok, err = h.finishConnect()
    if ok then break end
    if err or require("computer").uptime() > deadline then h.close(); return false end
    os.sleep(0.05)
  end
  local buf = ""
  while true do
    local chunk = h.read(math.huge)
    if chunk then buf = buf .. chunk else break end
  end
  h.close()
  local dir = path:match("^(.*)/[^/]+$")
  if dir and not fs.exists("/" .. dir) then fs.makeDirectory("/" .. dir) end
  local f = io.open("/" .. path, "w")
  if not f then return false end
  f:write(buf); f:close()
  return true
end

local LIBS = {
  "shared/protocol", "shared/netsec", "shared/sha2", "shared/util", "shared/roles",
  "shared/doors", "shared/site", "shared/protocols", "shared/reactors", "shared/defense", "shared/branding",
  "mineos/lib/net", "mineos/lib/card", "mineos/lib/session", "mineos/lib/writer", "mineos/lib/blackout",
  "mineos/login-fork/patch", "mineos/login-fork/autorun",
}
local APPS = {
  "SecurityConsole", "Access", "Accounts", "Badges", "Logs", "Messages",
  "Fleet", "Protocols", "Reactor", "Defense", "Config", "Map", "Setup",
}

print("Mise a jour SecSite...")
local nlib, napp = 0, 0
for _, l in ipairs(LIBS) do if download("Libraries/" .. l .. ".lua") then nlib = nlib + 1 end end
for _, a in ipairs(APPS) do
  if download("Applications/" .. a .. ".app/Main.lua") then napp = napp + 1 end
  pcall(system.createShortcut, paths.user.desktop .. a, "/Applications/" .. a .. ".app")
end
print("Libs: " .. nlib .. "/" .. #LIBS .. "  Apps: " .. napp .. "/" .. #APPS .. "  + icones bureau")
print("Termine - redemarre ou rafraichis le bureau.")
