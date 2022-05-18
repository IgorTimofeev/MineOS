
[English](https://github.com/IgorTimofeev/MineOS/) | 中文(简体) | [Русский](https://github.com/IgorTimofeev/MineOS/blob/master/README-ru_RU.md)

## MineOS独立版现已发布!

你好，亲爱的朋友。感谢你在漫长的开发周期中与我们并肩同行。MineOS终于到了发布阶段：现在它是一个完全独立的操作系统，拥有自己的开发API和一个讲解了使用方法且[图文并茂的维基](https://github.com/IgorTimofeev/MineOS/wiki).
MineOS是一个拥有GUI的操作系统，运行在Minecraft模组Open Computers上。它有广泛而强大的定制能力，以及一个能让你在社区中发布你的作品的<del>应用程序市场</del>（目前离线）。下面是它的特性的列表:
-   多任务处理
-   双缓冲图形用户界面
-   语言包和软件本地化
-   具有密码身份认证的多用户配置文件
-   自有EEPROM固件，具有选择/格式化/重命名引导卷的功能和Internet恢复模式
-   通过调制解调器在本地网络上共享文件
-   可连接到现实FTP服务器的客户端
-   具有语法高亮显示和调试器的内置IDE
-   <del>能够让每一个MineOS用户发布应用程序的应用市场</del>
-   错误报告系统，可向开发人员发送错误信息
-   动画、壁纸、屏幕保护程序、配色方案和巨大的定制空间
-   开源的系统API和详细的说明文档

## 如何安装?

最简单的方式是使用默认的**wget**脚本。插入一个OpenOS的软盘到计算机当中，再插入一个Internet卡，启动电脑并在控制台中输入下列命令以安装MineOS：

	wget -f https://raw.githubusercontent.com/IgorTimofeev/MineOS/master/Installer/BIOS.lua /tmp/bios.lua && flash -q /tmp/bios.lua && reboot

过一会儿，一个制作优良的系统安装程序将会被启动。
安装程序将提示你选择你的首选语言、选择并格式化引导卷、创建用户配置文件并修改一些设置。
之后，系统便已安装成功。

## 如何创建应用程序并使用API?

[Wiki](https://github.com/IgorTimofeev/MineOS/wiki)
