local system = require("System")

local workspace, icon, menu = table.unpack({...})

system.addSetAsWallpaperMenuItem(menu, icon.path)
system.addUploadToPastebinMenuItem(menu, icon.path)