About
-----------------------------------------------------------

MineOS is half the operating system and half the graphical environment for OpenOS, which comes in OpenComputers mod by default. It has following features:

* Multitasking
* Windowed interface with double buffered graphics context
* Animations, wallpapers, screensavers and color schemes
* Language packs and software localization
* User authorization by password and biometrics
* Support for file sharing over the local network via modems
* Support for client connection to real FTP servers
* Error reporting system with the possibility to send information to developers
* Store applications with the possibility to publish their own creations and a system of user ratings
* An integrated IDE with a debugger and a significant amount of applications
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

MineOS uses the most advanced libraries to create UI applications. Below is a table with illustrated documentation for libraries that are highly recommended for reading:

| Library | Documentation |
| ------- | ------- |
| GUI | https://github.com/IgorTimofeev/GUI |
| MineOSInterface | https://github.com/IgorTimofeev/MineOS/Documentaion/MineOSInterface.md |
| DoubleBuffering | https://github.com/IgorTimofeev/DoubleBuffering |
| Image | https://github.com/IgorTimofeev/Image |
| Color | https://github.com/IgorTimofeev/Color |
