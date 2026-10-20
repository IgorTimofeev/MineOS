local system = require("System")
local filesystem = require("Filesystem")
local screen = require("Screen")
local paths = require("Paths")
local GUI = require("GUI")
local paths = require("Paths")

--------------------------------------------------------------------------------

local workspace, wallpaper = select(1, ...), select(2, ...)

local configPath = table.concat {
    paths.user.applicationData,
    "Wallpapers/",
    filesystem.hideExtension(
        filesystem.name(
            filesystem.path(
                system.getCurrentScript()
            )
        )
    ),
    ".cfg"
}

local config = {
    color = 0x161616,
    useSystemTheme = true
}

if filesystem.exists(configPath) then
    for key, value in pairs(filesystem.readTable(configPath)) do
        config[key] = value
    end
end

local function saveConfig()
    filesystem.writeTable(configPath, config)
end

--------------------------------------------------------------------------------

wallpaper.draw = function(object)
    screen.drawRectangle(
        object.x, 
        object.y, 
        object.width, 
        object.height, 
        config.useSystemTheme 
            and system.getSystemTheme().background1 
            or config.color, 
        0, 
        ' '
    )
end

wallpaper.configure = function(layout)
    local switch = layout:addChild(
		system.applyThemeToSwitchAndLabel(
			GUI.switchAndLabel(
				1, 
				1, 
				36, 
				6, 
				0x66DB80, 
				0xE1E1E1, 
				0xFFFFFF, 
				0xA5A5A5, 
				"Use system theme", 
				config.useSystemTheme
			)
		)
	).switch

    switch.onStateChanged = function()
        config.useSystemTheme = switch.state
        saveConfig()
    end

    layout:addChild(
        GUI.colorSelector(
            1, 
            1, 
            36, 
            3, 
            config.color, 
            "Color"
        )
    ).onColorSelected = function(_, object)
        config.color = object.color
        saveConfig()
    end
end