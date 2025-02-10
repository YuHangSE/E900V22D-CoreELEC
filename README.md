# E900V22D-CoreELEC
CoreELEC packaging script applicable to E900V22D, automatically built using GitHub Actions.  
// 适用于**E900V22D**的CoreELEC打包脚本，使用GitHub Actions自动构建.

[Releases](https://github.com/YuHangSE/E900V22D-CoreELEC/releases)

## 以下为原项目的README.md // The following is the README.md of the original project
### CM311-1a-CoreELEC
适用于**魔百和CM311-1a**的CoreELEC打包脚本，开启蓝牙，增加蓝牙遥控器支持，改了一下LED指示灯

在 [KryptonLee/e900v22c-CoreELEC](https://github.com/KryptonLee/e900v22c-CoreELEC.git) 的基础上进行了修改

`common-files/{advancedsettings.xml,backspace.xml,e900v22c.rc_keymap,fs-resize,rc_maps.cfg}` 来自于 [KryptonLee/e900v22c-CoreELEC](https://github.com/KryptonLee/e900v22c-CoreELEC.git)

`common-files/CMCC_Voice_Remote.hwdb` 为蓝牙遥控器按键文件

`common-files/e900V22d.dtb` 是盒子的dtb文件，由于CM311-1a没有wifi,dtb中删除了关于wifi部分

用法 (Ubuntu 20.04 LTS)
```
sudo apt-get update -y
sudo apt-get install -y make gcc git texinfo gzip squashfs-tools
```

```
cd ~

git clone https://github.com/Heisenberg5201314/E900V22D-CoreELEC.git
cd E900V22D-CoreELEC
sh build.sh
```
有可能需要输入sudo密码
