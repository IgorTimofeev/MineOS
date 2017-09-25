
local MineOSPaths = {}

----------------------------------------------------------------------------------------------------------------

MineOSPaths.OS = "/MineOS/"
MineOSPaths.downloads = MineOSPaths.OS .. "Downloads/"
MineOSPaths.system = MineOSPaths.OS .. "System/"
MineOSPaths.applicationData = MineOSPaths.system .. "Application data/"
MineOSPaths.extensionAssociations = MineOSPaths.system .. "ExtensionAssociations/"
MineOSPaths.localizationFiles = MineOSPaths.system .. "Localization/"
MineOSPaths.icons = MineOSPaths.system .. "Icons/"
MineOSPaths.applications = MineOSPaths.OS .. "Applications/"
MineOSPaths.pictures = MineOSPaths.OS .. "Pictures/"
MineOSPaths.desktop = MineOSPaths.OS .. "Desktop/"
MineOSPaths.applicationList = MineOSPaths.system .. "Applications.cfg"
MineOSPaths.trash = MineOSPaths.OS .. "Trash/"
MineOSPaths.properties = MineOSPaths.system .. "Properties.cfg"
MineOSPaths.editor = MineOSPaths.applications .. "/MineCode IDE.app/Main.lua"
MineOSPaths.explorer = MineOSPaths.applications .. "/Finder.app/Main.lua"

----------------------------------------------------------------------------------------------------------------

return MineOSPaths