# Security Policy

<p>
  <a href="#zh">简体中文</a> ·
  <a href="#en">English</a>
</p>

---

<h2 id="zh">简体中文</h2>

### 支持范围

当前 `main` 上的正式版本（官网 zip / GitHub Releases）为积极维护对象。Xcode Debug / DerivedData 包不在支持范围。

### 如何报告

若问题涉及权限提升、LaunchDaemon、SMC 写入或助手进程，请：

1. 不要公开利用步骤或 PoC
2. 用 GitHub Security Advisories（优先）或私下联系维护者
3. 说明机型、macOS 版本、MacFan 版本（卡片上的 v1.x.x）

Issues 里请只写「存在一类权限问题」，不要贴可复现攻击。

### 使用注意

- 写风扇转速需要管理员权限（root LaunchDaemon）
- 不建议长时间锁在最大转速
- 测试结束后切回 **系统自动**
- Apple Silicon 上 `thermalmonitord` 仍可能覆盖用户写入

---

<h2 id="en">English</h2>

### Supported versions

The current `main` release (website zip / GitHub Releases) is actively maintained. Xcode Debug / DerivedData builds are unsupported.

### Reporting

For privilege escalation, the LaunchDaemon, SMC writes, or the helper process:

1. Do not publish exploit steps or a PoC
2. Prefer GitHub Security Advisories, or contact a maintainer privately
3. Include Mac model, macOS version, and the MacFan version on the auth card

In public issues, say that a privilege issue exists — do not attach a reproduction.

### Usage notes

- Writing fan RPM needs administrator rights (root LaunchDaemon)
- Do not leave max speed locked for long sessions
- Restore **System Auto** when you are done
- On Apple Silicon, `thermalmonitord` may still override user writes
