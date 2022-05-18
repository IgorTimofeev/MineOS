
local paths = {system = {}, user = {}}

--------------------------------------------------------------------------------

paths.system.libraries = "/Libraries/"
paths.system.applications = "/Applications/"
paths.system.icons = "/Icons/"
paths.system.localizations = "/Localizations/"
paths.system.extensions = "/Extensions/"
paths.system.mounts = "/Mounts/"
paths.system.temporary = "/Temporary/"
paths.system.pictures = "/Pictures/"
paths.system.screensavers = "/Screensavers/"
paths.system.users = "/Users/"
paths.system.versions = "/Versions.cfg"

paths.system.applicationSample = paths.system.applications .. "Sample.app/"
paths.system.applicationAppMarket = paths.system.applications .. "App Market.app/Main.lua"
paths.system.applicationMineCodeIDE = paths.system.applications .. "MineCode IDE.app/Main.lua"
paths.system.applicationFinder = paths.system.applications .. "Finder.app/Main.lua"
paths.system.applicationPictureEdit = paths.system.applications .. "Picture Edit.app/Main.lua"
paths.system.applicationSettings = paths.system.applications .. "Settings.app/Main.lua"
paths.system.applicationPrint3D = paths.system.applications .. "3D Print.app/Main.lua"
paths.system.applicationConsole = paths.system.applications .. "Console.app/Main.lua"
paths.system.applicationPictureView = paths.system.applications .. "Picture View.app/Main.lua"

--------------------------------------------------------------------------------

function paths.create(what)
	for _, path in pairs(what) do
		if path:sub(-1, -1) == "/" then
			require("Filesystem").makeDirectory(path)
		end
	end
end

function paths.getUser(name)
	local user = {}

	user.home = paths.system.users .. name .. "/"
	user.applicationData = user.home .. "Application data/"
	user.desktop = user.home .. "Desktop/"
	user.libraries = user.home .. "Libraries/"
	user.applications = user.home .. "Applications/"
	user.pictures = user.home .. "Pictures/"
	user.screensavers = user.home .. "Screensavers/"
	user.trash = user.home .. "Trash/"
	user.settings = user.home .. "Settings.cfg"
	user.versions = user.home .. "Versions.cfg"

	return user
end

function paths.updateUser(...)
	paths.user = paths.getUser(...)
end

--------------------------------------------------------------------------------

return paths
