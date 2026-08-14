# MacFan

**精准控制 Mac 风扇转速。**  
原生 SwiftUI 工具，支持 **Apple Silicon（M 系列）** 与 **Intel** Universal Binary。  
当前版本 **1.1.0** · [官网](https://linux503.github.io/MacFan/) · [下载](https://linux503.github.io/MacFan/assets/MacFan-1.1.0-macos.zip)

<p align="center">
  <img src="MacFan-logo.png" width="160" alt="MacFan logo" />
</p>

<p align="center">
  <a href="https://linux503.github.io/MacFan/">官网</a> ·
  <a href="#功能">功能</a> ·
  <a href="#安装与运行">安装</a> ·
  <a href="#权限说明">权限</a>
</p>

### 1.1 更新
- **Signal Night** 全新深蓝 + 信号蓝配色  
- 菜单栏图标更大更清晰  
- 管理员授权改为后台 SMC 助手（无需整应用以 root 重启）  
- 官网海报与直接下载包  

---

## 功能

### 核心控制
| 模式 | 说明 |
|------|------|
| **最大转速** | 一键拉满全部风扇 |
| **手动调节** | 逐风扇精确设定目标 RPM |
| **系统自动** | 交还 macOS SMC 温控 |
| **场景模式** | 按温度曲线智能运行 |

### 特色场景
- **静音办公** — 文档 / 会议，优先低噪  
- **影音观影** — 安静优先  
- **创作渲染** — Xcode / Final Cut / Photoshop 等自动加压散热  
- **游戏竞技** — 高风量压制掉温  
- **极速散热** — 全风扇最大  
- **夜间静音** — 23:00–07:00 自动压转速  

### 扩展能力
- **应用联动**：前台 App 命中规则时自动切场景  
- **夜间调度**：按时段切换曲线  
- **温度轨迹**：CPU / GPU 历史曲线  
- **菜单栏常驻**：快捷最大转速 / 自动 / 静音办公  
- **程序坞图标 + 自定义菜单栏图标**

---

## 语言与更新

- **中英双语**：App 内可切换，**默认中文**（不跟随系统语言）
- **检查更新**：读取官网 `version.json`，失败时回退 GitHub Releases
- **访问官网**：侧栏 / 菜单栏 / ⌘0 可打开 https://linux503.github.io/MacFan/

---

## 安装与运行

### 要求
- macOS 14.0+
- Xcode 15+（本地构建）
- 实机调速需管理员权限（写入 SMC）

### 用 Xcode 运行
```bash
git clone https://github.com/linux503/MacFan.git
cd MacFan
open MacFan.xcodeproj
```
选择 **My Mac**，按 ⌘R。

### 命令行构建
```bash
xcodebuild -scheme MacFan -configuration Release -destination 'platform=macOS' build
```

首次实控风扇时，在 App 内点击 **「以管理员身份启动」** 并输入密码。

---

## 权限说明

| 能力 | 是否需要管理员 |
|------|----------------|
| 读取风扇转速 / 温度 | 通常不需要 |
| 写入目标转速 / 最大转速 | **需要**（root） |
| Apple Silicon（尤其 M3/M4） | 可能需 `Ftst` 解锁以绕过 `thermalmonitord` |

> 长时间手动控温后，请切回 **系统自动**，把温控交还系统。

---

## 技术架构

```
MacFan/
├── MacFan/                 # SwiftUI App
│   ├── Models/             # 场景、风扇、温度模型
│   ├── Services/           # SMC 客户端、联动、ViewModel
│   ├── SMC/                # AppleSMC C 桥接（读/写风扇）
│   └── Views/              # 侧栏、仪表盘、菜单栏、主题
├── docs/                   # 官网（GitHub Pages）
└── MacFan.xcodeproj
```

- **UI**：SwiftUI + `MenuBarExtra`  
- **硬件**：`AdaptiveFanController` + `SMCClient`（Intel / Apple Silicon）  
- **架构**：`arm64` + `x86_64` Universal  

---

## 官网

营销页与产品介绍：  
**https://linux503.github.io/MacFan/**

本地预览：
```bash
open docs/index.html
```

---

## 路线图

- [ ] 签名 Privileged Helper（免每次输入密码）
- [ ] 自定义温度曲线编辑器
- [ ] 导出 / 导入场景配置
- [ ] Sparkle 自动更新

---

## License

[MIT](LICENSE) © 2026 MacFan
