# 贡献指南

<p>
  <a href="./CONTRIBUTING.md">简体中文</a> ·
  <a href="./CONTRIBUTING.en.md">English</a>
</p>

感谢关注 [MacFan](README.md)。先看产品说明，再改风扇相关代码。

## 环境

- macOS 14+
- Xcode 15+
- 实机（读写 SMC；模拟器 / 预览数据不能代表真机）

## 流程

1. Fork，分支用 `feature/xxx` 或 `fix/xxx`
2. 改动尽量小，一次只做一件事
3. 在真机上用 **Release** 或官网 zip 验证授权与写转速
4. 不要用 DerivedData 里的 Debug 包测管理员助手
5. Commit 写清「为什么」
6. 开 Pull Request

## 代码约定

- SwiftUI 跟现有 `MFTheme` 色板，不要另起一套颜色
- 文案进 `MacFan/Services/L10n.swift`，**中英都要补**
- SMC 读写只放在 `MacFan/SMC` 与 `Services/SMCClient.swift`
- 管理员安装脚本是 `MacFan/Resources/install-smc-helper.sh`（不要再引入 nohup / python3）
- 官网在 `docs/`；改样式后记得 bump `?v=`
- 不要提交 DerivedData、用户态 Xcode 文件、密钥、`AppIcon-preview.png`

## 验证

```bash
xcodebuild -scheme MacFan -configuration Release -destination 'platform=macOS' build
```

- 窗口卡片显示当前版本号
- 授权后能改 RPM，切回「系统自动」能恢复
- 关掉主窗口后菜单栏仍在，且可以退出

## 安全

风扇控制会写入 SMC。真机测试结束请恢复 **系统自动**。安全报告见 [SECURITY.md](SECURITY.md)。
