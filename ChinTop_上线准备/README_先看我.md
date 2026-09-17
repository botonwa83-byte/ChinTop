# ChinTop 上线准备包

生成于 2026-09-17，对应版本 1.0.0(1)，Bundle ID `com.chintop.app`。

> 隐私政策 / 用户协议 / 技术支持正文统一放在仓库根目录 `docs/`（`docs/index.html`、`docs/privacy.html`、`docs/terms.html`、`docs/support.html`），本包不再保留副本，避免两处文案不一致。

## 文件导览

| 文件 | 用途 |
|------|------|
| `00_上线总检查清单.md` | 从这里开始：阻断项、后台待办、已验证项 |
| `01_App Store商品信息.md` | 名称、副标题、关键词、描述、更新说明，可直接复制 |
| `04_App隐私问卷答案.md` | App Privacy 问卷答案，结论：不收集数据 |
| `05_审核备注_ReviewNotes.md` | 审核备注，中英双语，含内购测试路径 |
| `06_内购配置_IAP.md` | ASC 内购参数，产品 ID 与代码一致性核对 |
| `07_年龄分级问卷.md` | 年龄分级逐项答案，建议 4+ |
| `08_截图与素材清单.md` | 截图尺寸、建议取景、内购截图要求 |
| `09_GitHub_Pages_托管说明.md` | privacy / terms / support 静态页托管说明 |

## 本轮整改已完成的工程项

- 题库批次接线修复：`all` 已并入 batch4/5/6，总数 307（原仅 187，付费用户此前只能看到约六成题目）。
- 免费档常量化：`ChinQuestionBank.freeQuestionCount`，由 `testFreeTierPolicy` 守门。
- 工程配置：iPad 四向支持、`ITSAppUsesNonExemptEncryption=NO`、单元测试 target 已进工程。
- 合规入口：付费墙与「功能」页均接了用户协议 / 隐私政策 / 技术支持链接。
- 隐私清单：`ChinTopApp/Resources/PrivacyInfo.xcprivacy`（声明仅使用 UserDefaults）。
- 图标 alpha 已压平（1024×1024，无透明通道）。

## 提交前仍需人工完成

1. ASC 创建内购 `com.chintop.app.full_unlock`（¥22，随版本提交）。
2. 推送仓库后在 Settings → Pages 启用 `main /docs`，并验证三个 URL 可访问。
3. 补齐 iPhone 6.9" 与 iPad 13" 截图。
4. 实机走一遍内购：购买 / 恢复 / 取消 / 删除重装恢复。
