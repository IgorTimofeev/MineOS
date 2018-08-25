About
-----------------------------------------------------------

MineOS is half the operating system and half the graphical environment for OpenOS, which comes in OpenComputers mod by default. Originally it was developed in Russian, but it supports several languages. MineOS has following features:

* Multitasking
* Windowed interface with double buffered graphics context
* Animations, wallpapers, screensavers and color schemes
* Language packs and software localization
* User authorization by password and biometrics
* Support for file sharing over the local network via modems
* Support for client connection to real FTP servers
* Error reporting system with the possibility to send information to developers
* App Market with enormous amount of wonderful applications and possibility to publish your own programs for every MineOS user
* An internal IDE with syntax highlighting and debugger
* Open source system API and detailed illustrated documentations
* Custom EEPROM firmware with the possibility to select/format the boot volume and Internet recovery
* Almost complete compatibility with OpenOS software

Installation
-----------------------------------------------------------

Make sure that your computer meets the minimum configuration before installation:

| Device | Tier | Count |
| ----- | ----- | ----- |
| Computer case | 3 | 1 |
| Screen | 3 | 1 |
| Keyboard | - | 1 |
| CPU | 3 | 1 |
| GPU | 3 | 1 |
| RAM | 3.5 | 2 |
| Internet card | - | 1 |
| EEPROM (Lua BIOS) | - | 1 |
| OpenOS floppy | - | 1 |

It is also recommended to add a wireless modem to connect computers to the home network. Now you can turn on the computer. By default, the OpenOS boots from the inserted floppy, you just have to install it on your hard disk, similar to installing a real OS. Use the **install** command:

![](https://i.imgur.com/lpwwQD4.png?1)

After the installation is complete, you will be prompted to make the hard disk bootable, and restart the computer. After rebooting, you can start installing MineOS. To do this, enter the following command in the console:

    pastebin run 0nm5b1ju

The computer will be analyzed for compliance with the minimum requirements, after which a pretty installer will be launched. You can change some system options to your taste, and, agreeing with the license agreement, install MineOS.

How to develop MineOS applications
-----------------------------------------------------------

Each MineOS application is a directory with **.app** extension, which has the following contents:

![](https://i.imgur.com/o6uiNBJ.png)

The **Main.lua** file is launched on application start, and **Icon.pic** is used to display application icon. The easiest way to create an application is to click on the corresponding option in the context menu:

![](https://i.imgur.com/SqBAlJo.png)

You will be asked to choose the name of your application, as well as its icon. If the icon is not choosen, then the system icon will be used. To modify the source code of an application, just edit the **Main.lua** file.

MineOS uses the most advanced libraries to create UI software. Below is a table with illustrated documentation for libraries that are highly recommended for reading:

| Library | Documentation |
| ------- | ------- |
| GUI | https://github.com/IgorTimofeev/GUI |
| DoubleBuffering | https://github.com/IgorTimofeev/DoubleBuffering |
| Image | https://github.com/IgorTimofeev/Image |
| Color | https://github.com/IgorTimofeev/Color |

Now you can create some cool apps. Use **MineOSInterface** library that comes bundled with MineOS: it implements the main system widgets, and is also responsible for all windows manipulations. It has following public methods:

MineOSInterface.**addWindow**( window ): *table* mainContainer, *table* window
-----------------------------------------------------------

| Type | Parameter | Description |
| ------ | ------ | ------ |
| *table* | window | Pointer to the window object |

Adds the window object that was created via **GUI library** to the MineOS environment, registers its icon in the Dock and add event handlers to it. First returned value is the MineOS main container that handles all event data and the second one is a pointer to your window object.

Here is nice example of tabbed window that can change its "brightness" in real time:

```lua
local color = require("color")
local GUI = require("GUI")
local MineOSInterface = require("MineOSInterface")

-------------------------------------------------------------------------------

-- Create a tabbed window and register it in MineOS environment
local mainContainer, window = MineOSInterface.addWindow(GUI.tabbedWindow(1, 1, 88, 25))

-- Add some stuff into it's tab bar
window.tabBar:addItem("Tab 1")
window.tabBar:addItem("Tab 2")
window.tabBar:addItem("Tab 3")
window.tabBar:addItem("Yay another tab")

-- Add a single cell layout to window
local layout = window:addChild(GUI.layout(1, 4, window.width, window.height - window.tabBar.height, 1, 1))

-- Add a horizontal slider to layout
local slider = layout:addChild(GUI.slider(1, 1, 26, 0x66DB80, 0x0, 0x009200, 0xAAAAAA, 0, 100, 100, false, "Brightness: ", "%"))
-- Attach callback-function .onValueChanged to it
slider.onValueChanged = function()
	-- Calculate "brightness" color value
	local channelValue = math.floor(slider.value / slider.maximumValue * 255)
	local newColor = color.RGBToInteger(channelValue, channelValue, channelValue)
	-- Set new color to all required widgets
	window.backgroundPanel.colors.background = newColor
	window.tabBar.colors.selected.background = newColor
	window.tabBar.colors.selected.text = 0xFFFFFF - newColor
	-- Draw changes on screen
	mainContainer:drawOnScreen()
end

-- Call slider callback function once to calculate brightess and draw data on screen
slider.onValueChanged()
```

Result:

![](https://i.imgur.com/TUDdkl2.gif)
