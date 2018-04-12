
local filesystem = require("filesystem")
local MineOSPaths = {}

---------------------------------------------------------------------------

MineOSPaths.OS = "/MineOS/"
MineOSPaths.downloads = MineOSPaths.OS .. "Downloads/"
MineOSPaths.system = MineOSPaths.OS .. "System/"
MineOSPaths.applicationData = MineOSPaths.system .. "Application data/"
MineOSPaths.extensionAssociations = MineOSPaths.system .. "Extensions/"
MineOSPaths.localizationFiles = MineOSPaths.system .. "Localizations/"
MineOSPaths.icons = MineOSPaths.system .. "Icons/"
MineOSPaths.applications = MineOSPaths.OS .. "Applications/"
MineOSPaths.pictures = MineOSPaths.OS .. "Pictures/"
MineOSPaths.desktop = MineOSPaths.OS .. "Desktop/"
MineOSPaths.fileVersions = MineOSPaths.system .. "File versions.cfg"
MineOSPaths.trash = MineOSPaths.OS .. "Trash/"
MineOSPaths.properties = MineOSPaths.system .. "Properties.cfg"
MineOSPaths.editor = MineOSPaths.applications .. "/MineCode IDE.app/Main.lua"
MineOSPaths.explorer = MineOSPaths.applications .. "/Finder.app/Main.lua"
MineOSPaths.imageEditor = MineOSPaths.applications .. "/Picture Edit.app/Main.lua"
MineOSPaths.temporary = MineOSPaths.system .. "Temporary/"
MineOSPaths.network = MineOSPaths.system .. "Network/"

---------------------------------------------------------------------------

filesystem.makeDirectory(MineOSPaths.pictures)
filesystem.makeDirectory(MineOSPaths.applicationData)
filesystem.makeDirectory(MineOSPaths.trash)
filesystem.makeDirectory(MineOSPaths.desktop)
filesystem.makeDirectory(MineOSPaths.network)

---------------------------------------------------------------------------

return MineOSPaths