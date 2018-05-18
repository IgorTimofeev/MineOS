About
======

MineOSInterface is a library that comes bundled with MineOS. It implements the main system widgets, and is also responsible for all windows manipulations. She works in tandem with **[GUI](https://github.com/IgorTimofeev/GUI)** и **[doubleBuffering](https://github.com/IgorTimofeev/DoubleBuffering)** libraries, that's why a preliminary familiarization with them is highly desirable.

MineOSInterface.**addWindow**( window ): *table* mainContainer, *table* window
-----------------------------------------------------------

| Type | Parameter | Description |
| ------ | ------ | ------ |
| *table* | window | Window object that was created by GUI library |

Adds the created window to the MineOS environment, registers its icon in the Dock and add event handlers to it. First returned value is the MineOS main container that handles all event data and the second one is a pointer to your window object. You can use code like this (again, read GUI library documentation for details):

```lua
local MineOSInterface = require("MineOSInterface")

-----------------------------------------------------------

local mainContainer, window = MineOSInterface.addWindow(MineOSInterface.tabbedWindow(1, 1, 88, 25))
window.tabBar:addItem("Приложения")
window.tabBar:addItem("Библиотеки")
window.tabBar:addItem("Обои")
window.tabBar:addItem("Обновления")

mainContainer:drawOnScreen()
```

Result:

![](https://i.imgur.com/294FatT.png?1)