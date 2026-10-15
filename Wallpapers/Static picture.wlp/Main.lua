local system = require("System")
local filesystem = require("Filesystem")
local screen = require("Screen")
local GUI = require("GUI")
local image = require("Image")

--------------------------------------------------------------------------------

local workspace, wallpaper = select(1, ...), select(2, ...)

local configPath = filesystem.path(system.getCurrentScript()) .. "Config.cfg"

local config = {
    path = filesystem.path(system.getCurrentScript()) .. "Pictures/Girl.pic"
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

local picture, reason

local function loadPicture()
   picture, reason = image.load(config.path)
end

local function setPicture(path)
    config.path = path
    loadPicture()
    saveConfig()
end

loadPicture()

--------------------------------------------------------------------------------

wallpaper.draw = function(object)
    screen.drawRectangle(
        object.x, 
        object.y, 
        object.width, 
        object.height, 
        system.getSystemTheme().background1, 
        0x000000, 
        " "
    )

    if picture then
        screen.drawImage(
            object.x + math.floor((object.width  - image.getWidth (picture)) / 2), 
            object.y + math.floor((object.height - image.getHeight(picture)) / 2), 
            picture
        )
    else
        local text = reason or "Unknown reason"

        screen.drawText(
            math.floor(object.x + object.width / 2 - unicode.len(text) / 2), 
            math.floor(object.y + object.height / 2), 
            0x646464,
            text
        )
    end
end

wallpaper.configure = function(layout)
    local chooser = layout:addChild(
        system.applyThemeToFilesystemChooser(
            GUI.filesystemChooser(
                1, 
                1, 
                36, 
                3, 
                0xE1E1E1, 
                0x696969, 
                0xD2D2D2, 
                0xA5A5A5, 
                config.path, 
                "Open", 
                "Cancel", 
                "Wallpaper path", 
                "/"
            )
        )
    )

    chooser:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
    chooser:addExtensionFilter(".pic")
    chooser.onSubmit = setPicture
end

wallpaper.setPicture = setPicture