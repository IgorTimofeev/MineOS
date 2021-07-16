English | [中文(简体)](https://github.com/IgorTimofeev/MineOS/blob/master/README-zh_CN.md) | [Русский](https://github.com/IgorTimofeev/MineOS/blob/master/README-ru_RU.md)

## MineOS Standalone has released!

Hello again, dear friend. Thank you for being with us and supporting our ideas throughout the long development cycle. MineOS has finally reached the release stage: now it is a completely independent operating system with its own development API and wonderful [illustrated wiki](https://github.com/IgorTimofeev/MineOS/wiki) of it's usage. 
MineOS is a GUI based operating system for the Open Computers Minecraft mod. It has extensive and powerful customisation abilities as well as an app market to publish your creations among the OS community.
Here's a list of a few features:

-   Multitasking
-   Double buffered graphical user interface
-   Language packs and software localization
-   Multiple user profiles with password authentication
-   Own EEPROM firmware with boot volume choose/format/rename features and Internet Recovery mode
-   File sharing over the local network via modems
-   Client connections to real FTP servers
-   An internal IDE with syntax highlighting and debugger
-   Integrated application and library App Market with the ability to publish your own scripts and programs for every MineOS user
-   Error reporting system with the possibility to send information to developers
-   Animations, wallpapers, screensavers, color schemes and huge customization possibilities
-   Open source system API and detailed illustrated documentations

## How to install?

The easiest way is to use default **pastebin** script. Insert an OpenOS floppy disk to computer, insert an Internet Card, turn computer on and type the following to console to install MineOS:

	pastebin run 0nM5b1jU

You can paste it to console using middle mouse button or insert key (by default). If for some reason the pastebin method isn't available to you (for example, it's blacklisted on game server or blocked by Internet provider), use alternative command to download the installer directly from the Github page:

	wget -f https://raw.githubusercontent.com/IgorTimofeev/MineOS/master/Installer/BIOS.lua /tmp/bios.lua && flash -q /tmp/bios.lua && reboot

After a moment, a nice system installer will be shown. You will be prompted to select your preferred language, boot volume (can be formatted if needed), create a user profile and customize some settings

## How to create applications and work with API?

[Wiki](https://github.com/IgorTimofeev/MineOS/wiki)
