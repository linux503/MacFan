# 贡献指南

感谢关注 MacFan。

## 开发环境
- macOS 14+
- Xcode 15+

## 流程
1. Fork 并创建分支：`feature/xxx` 或 `fix/xxx`
2. 保持改动小而聚焦
3. 本地用 Xcode 构建验证
4. 提交清晰的 commit message（说明「为什么」）
5. 打开 Pull Request

## 代码约定
- SwiftUI 视图遵循现有 `MFTheme` 色板
- SMC 读写逻辑放在 `MacFan/SMC` 与 `Services/SMCClient.swift`
- 不要提交 DerivedData、用户态 Xcode 文件或密钥

## 安全提醒
风扇控制会写入 SMC。请在真实硬件上谨慎测试，并在结束后恢复「系统自动」。
