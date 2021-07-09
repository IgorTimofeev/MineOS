
[English](https://github.com/IgorTimofeev/MineOS/) | 中文(简体) | [Русский](https://github.com/IgorTimofeev/MineOS/blob/master/README-ru_RU.md)

## MineOS独立版已经发布!

你好, 亲爱的朋友. 感谢您在漫长的开发周期中与我们在一起并支持我们的想法. MineOS终于到了发布阶段: 现在它是一个完全独立的操作系统, 拥有自己的开发API和出色的
[插图维基](https://github.com/IgorTimofeev/MineOS/wiki).
MineOS是一个基于GUI的Minecraft Opencomputers模组的操作系统. 它有广泛和强大的定制能力, 以及一个应用程序市场, 在社区中发布你的创作.
下面是一些特性的列表:
-   多任务处理
-   双缓冲GUI
-   语言包和软件本地化
-   具有密码身份认证的多用户配置文件
-   拥有EEPROM固件, 具有引导卷选择/格式化/重命名功能和Internet恢复模式
-   通过网卡在本地网络上共享文件
-   到真实世界FTP服务器的客户端连接
-   具有语法高亮显示和调试器的内部IDE
-   为每个MineOS用户发布程序的应用程序市场
-   错误报告系统, 可向开发人员发送信息
-   动画, 壁纸, 屏幕保护程序, 配色方案和巨大的定制可能性
-   开源系统API和详细的说明文档

## 如何安装?

最简单的方法是使用默认的 **pastebin** 脚本. 
插入OpenOS软盘, 插入Internet网卡, 开启电脑, 打开并在控制台中输入以下命令, 将操作系统写入已安装的硬盘:

	pastebin run 0nM5b1jU

你可以使用鼠标中键或Insert键将其粘贴到控制台(默认情况下). 
如果由于某种原因pastebin方法对你不可用(例如, 它在游戏服务器上被列入黑名单, 或者被互联网提供商屏蔽), 
使用替代命令直接从Github页面下载安装程序:

	wget -f https://raw.githubusercontent.com/IgorTimofeev/MineOS/master/Installer/BIOS.lua /tmp/bios.lua && flash -q /tmp/bios.lua && reboot

如果由于某种原因Github方法对你不可用(例如, 它在游戏服务器上被列入黑名单, 或者被互联网提供商屏蔽), 
使用替代命令直接从镜像页面下载安装程序:

	wget -f https://mirror.opencomputers.ml:1337/MineOS/IgorTimofeev/MineOS/master/Installer/BIOS.lua /tmp/bios.lua && flash -q /tmp/bios.lua && reboot

过一会儿, 一个很好的系统安装程序将显示. 
安装程序将提示您选择首选语言, 选择并格式化引导卷, 创建用户配置文件并自定义一些设置. 
之后, 系统将成功安装. 

## 如何\*做某事\*?

[Wiki](https://github.com/IgorTimofeev/MineOS/wiki)
