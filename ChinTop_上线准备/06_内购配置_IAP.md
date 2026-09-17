# ChinTop 内购配置（App Store Connect）

## 商品参数

| 项 | 值 |
|----|----|
| 类型 | 非消耗型 / Non-Consumable |
| 产品 ID | `com.chintop.app.full_unlock` |
| 参考名称（Reference Name） | `ChinTop Full Unlock` |
| 显示名称（中文） | `完整版解锁` |
| 价格 | ¥22 档位（以 ASC 实际价格档为准） |
| 家庭共享 | 关闭（非消耗型默认不可共享时保持关闭） |
| 审核截图 | 付费墙截图（建议 6.9" 一张） |

## 商品描述（ASC）

完整版解锁：开放五大专题（现代文阅读、文言文解码、古诗词鉴赏、考场作文升格、综合性学习）全部题目与解析，一次买断永久使用。免费部分（每专题前 3 题试练、能力地图、方法工具箱、错题复盘、成长报告）继续保持免费。无订阅、无续费，支持换机恢复购买。

## 代码一致性核对

| 位置 | 值 | 状态 |
|------|----|------|
| `ChinTopApp/ChinPurchaseManager.swift` → `productID` | `com.chintop.app.full_unlock` | ✅ |
| `ChinTopApp.storekit` → `productID` | `com.chintop.app.full_unlock` | ✅ |
| `project.yml` → `PRODUCT_BUNDLE_IDENTIFIER` | `com.chintop.app` | ✅ |
| 产品 ID 前缀与 bundle id 一致 | `com.chintop.app.` | ✅ |

## 免费档划线（代码中的常量）

- `ChinQuestionBank.freeQuestionCount = 3`：未解锁时每个专题/学段只开放前 3 题。
- 由 `Tests/ChinQuestionBankTests.swift` 的 `testFreeTierPolicy` 守门：每个专题/学段必须既有完整免费试练，又留有付费内容。
- 扩内容时**不要打乱数组前 3 题**，否则免费体验会变。

## 提交前

- ⬜ 在 ASC「App 内购买项目」创建上述商品，状态设为「准备提交」。
- ⬜ 在版本页「App 内购买项目」区域勾选本商品，随版本一起提交。
- ⬜ 用沙盒账号在 TestFlight 实测：购买成功解锁、恢复购买、取消不解锁、删除重装可恢复。
