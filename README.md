# Pico Screenshot HiRes — 系统截图高分辨率解锁 (Magisk 模块)

针对 **PICO 4 标准版 (A8110 / Phoenix, Android 10 / API 29)** 的系统截图分辨率解锁模块。
把系统截图的输出从默认 **1920×1920** 提升到 **2560×1440**。

**纯 Settings.Global 实现,无需 hook、无需 LSPosed。**

---

## 效果

| 项目 | 原厂默认 | 本模块 |
|---|---|---|
| 系统截图输出 | 1920×1920 (方形, 单目/wideFov 画布) | **2560×1440** |
| 实现方式 | — | 设 `pvr.video.resolution.width/height` |

- 截图服务 (`com.bytedance.pico.screencapture`) 每次截图**实时读取**这两个设置值。
- 这两个值**非零即直接用**作为截图输出分辨率 → 无需 hook。
- 改动即时生效(不必重启),可持续(开机由本模块重设)。

---

## 原理 (逆向结论)

PICO 截图链路:
```
按键/面板 → com.picovr.quicksettings → bind com.bytedance.pico.screencapture.ScreenCaptureService
  → ShotBusiness → BusinessManager.prepareScreen → ConstantKt.readResolution(context, wideType)
  → ScreenCapturer(w,h,...) → Screen.init() → DisplayManager.createVirtualDisplay(name, w, h, dpi,...)
```

`readResolution` 判定:
- 若 `Settings.Global("pvr.video.resolution.width")` 与 `.height` **均非零** → **直接用**这两个值。
- 否则走默认映射(基于 `ro.pvr.product.name` 的 eyeBuffer, Phoenix=1920 → 方形 1920×1920)。

本模块即把前两个设置值设为 2560/1440,让截图服务走"用户自定义分辨率"分支。

> 根因: 截图服务自己新建一个虚拟显示(独立于 2D 应用的 NS_APP 虚拟显示)来抓屏,
> 所以 resfix(改的是应用 NS_APP 虚拟显示)不影响截图输出分辨率 —— 两者是两条独立链路。

---

## 安装

把 `screenshot-hires-mod.zip` 用 **Magisk → 模块 → 从本地安装** 刷入,然后**重启**。
(或手动把整个目录推到 `/data/adb/modules/screenshot_hires/`, 设 0755 权限。)

脚本在开机 `boot_completed` 后自动设置 `2560x1440`。

## 使用 / 切换

```sh
su -c "sh /data/adb/modules/screenshot_hires/toggle.sh on"          # 启用(默认 2560x1440)
su -c "sh /data/adb/modules/screenshot_hires/toggle.sh off"         # 关闭(恢复系统默认)
su -c "sh /data/adb/modules/screenshot_hires/toggle.sh 3200 1800"   # 自定义分辨率并启用
```

改完**下一张截图即时生效**(服务每次现读),无需重启。

分辨率存于 `resolution.conf`(`ENABLE` / `W` / `H`)。

## 手动改 (不装模块)

```sh
settings put global pvr.video.resolution.width  2560
settings put global pvr.video.resolution.height 1440
```

---

## 目录

```
screenshot-hires-mod/
├─ module.prop      # Magisk 模块元信息
├─ service.sh       # 开机自启设置分辨率 (等待 boot_completed)
├─ toggle.sh        # 手动开关/自定义分辨率
└─ resolution.conf  # (运行时生成) ENABLE/W/H
```

## 构建模块 zip

```sh
cd screenshot-hires-mod
zip -r ../screenshot-hires-mod.zip . -x '*.git*'
```

---

## 验证方法

截一张图后看日志:
```sh
logcat -d | grep -iE 'new resolution|prepareScreen'
```
- 设置前: `new resolution value: 0 0` , `settings: (1920, 1920)`
- 设置后: `new resolution value: 2560 1440`, `settings: (2560, 1440)`

图片存于 `/sdcard/Pictures/Screenshots/`, 可直接 pull 对比分辨率。

---

## License
MIT
