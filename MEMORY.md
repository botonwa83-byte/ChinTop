# ChinTopNative 开发记忆

更新时间：2026 年 9 月 11 日（Asia/Shanghai）  
下次继续开发：2026 年 9 月 12 日

## 产品定位

本项目面向中小学学生，定位是“语文能力训练 App”，不是单纯增加题量的题库。

核心学习闭环：

> 学方法 → 做任务 → 写作品 → 看错因 → 再迁移

必须持续保持的产品边界：

- 不声称已经具备 AI 批改、云端同步、真实考试来源或自动生成的能力分数。
- 成长报告只能基于本设备上真实记录的题目、任务、作品和错题。
- 付费文案只承诺“完整题库解锁”；每日能力任务、作品库、错题复盘等现有功能继续免费可用。
- 后续优先增加方法、开放表达、复盘和迁移价值，不要只机械扩充选择题数量。

## 当前已完成

### 学习内容与能力模型

- 学习阶段：小学高年级、初中；两者有不同表达支架。
- 五项能力：
  - 证据提取
  - 结构推理
  - 规范表达
  - 创意写作
  - 复盘迁移
- 每日能力任务：先展示方法，再完成开放式答案，最后保存作品和下一步计划。
- 作品库：保存答案、自评清单、下一步反思。
- 错题复盘：保存错误答案、正确答案、解析，并可标记为已复盘。
- 成长报告：展示真实学习证据、能力状态和下一步建议，不生成虚假分数。
- 本周计划：按周生成 7 天任务路径。

### 方法工具箱

- `ChinMethodCard` / `ChinMethodCardCatalog` 已加入核心模型。
- 当前有 12 张方法卡，覆盖五项能力。
- 支持关键词搜索和按能力筛选。
- 方法卡包含步骤、示例、自我提醒，并可跳转到关联任务。
- 任务页也可以反向打开完整方法卡，形成双向闭环。
- 方法目录已增加 `card(forTaskID:)` 反查接口。

### 数据准确性修正

- 任务完成状态新增“日期 + 任务 ID”记录，避免下一周重复任务被错误显示为已完成。
- `ChinLearningSnapshot` 对新增字段提供自定义 Codable 解码，兼容旧版本本地快照。
- 错题记录新增可选 `capabilityID`。
- 选择题练习会根据专题和技能映射到更具体的能力，成长报告优先使用该能力；旧错题没有能力字段时仍按专题回退。

### 导航与支付

- 启动后直接进入学习首页。
- 侧边栏已接入：
  - 今日学习
  - 能力地图
  - 方法工具箱
  - 成长报告
  - 本周计划
  - 错题复盘
  - 我的作品
  - 五个专题练习
- 完整题库解锁使用 StoreKit 2（2026-09-11 参照 EngTop 修复）：一次性买断，产品 ID `com.chintop.app.full_unlock`，¥22；`ChinPurchaseManager` 启动时 `refreshEntitlements` 核验凭证（含 revocationDate 检查），购买/恢复有完整分支与错误提示。
- 本地调试：根目录 `ChinTopApp.storekit` 定义商品，`project.yml` schemes 在 run/test/profile 挂 `storeKitConfiguration`（xcodegen 重新生成后 scheme 含 StoreKitConfigurationFileReference）。
- 免费档：每专题每学段前 3 题试练；付费墙入口在模块页与"功能"页。
- 注意：App Store Connect 真实商品未配置，上线前需创建同 ID 商品并沙盒验收，不要说"支付已上线"。
- `ChinPromoView` 仍保留，但当前启动流程不展示营销页。

### 分学段题库（2026-09-11 重做并按权重扩充）

- `ChinQuestionBank` 持有 535 道人工编写题目（小学 258、初中 277）：首批 120 道（小学 60、初中 60）+ 按权重三批填充 67 道 + 第四轮均衡扩充 120 道（每个模块×学段区块 +12）；模板生成器与旧 `ChinLegacyQuestionBank` 死代码已删除。
- 权重模型：每个知识点在其覆盖学段内 core ≥ 4、supporting ≥ 3、extension ≥ 2（`ChinQuestionBank.targetCount(importance:)`），测试按权重断言，后续加题不受固定配额限制。
- 填充批次：批 1 阅读+文言 29、批 2 古诗词+作文 24、批 3 综合 14；批 4 阅读+文言 48、批 5 古诗词+作文 48、批 6 综合 24。
- 批 9（2026-09-14）按权重查缺补漏：小学 26、初中 38；批 10（2026-09-17）按知识点均衡扩容 +112（小学 58、初中 54）：两学段知识点各 +4、小学专属 +3、初中专属 +2，33 个知识点全部加厚。
- 加题硬约束（测试守护）：ID 唯一、题干唯一、选项互不相同、来源不含"真题/名校/官方题库/押题"。写新题前先跑一遍查重，名句型考点极易与旧题撞车。
- 知识点目录 33 个细粒度知识点（含学段覆盖声明），是模块"覆盖知识点"与练习筛选器的唯一数据源；`ChinModule.points` 重复清单已移除。
- 每题有稳定 ID（`primary-reading-01` 式）、知识点 ID、重要性、难度、来源（统一"本地精选练习 · 来源待核验"）。
- 能力映射改为知识点 ID 表驱动（`ChinCapability.capabilityID(knowledgePointID:moduleID:skill:)`），旧数据无知识点 ID 时回退中文关键词匹配。
- 错题元数据链路打通：`recordPractice` 全链路传递 `gradeID`/`knowledgePointID`/`difficulty`，旧错题再次作答时同步更新；旧快照解码保持兼容。

## 当前验证证据

2026 年 9 月 11 日已验证：

```bash
swift test
```

- `ChinQuestionBankTests` 13 项全通过（新增 112 题后仍全绿）。
- 覆盖权重题量、题干唯一、选项去重、知识点-学段覆盖、来源诚信标注、能力映射有效性、错题元数据落库重载、旧快照（缺 `completedTaskKeys`/题目元数据）解码、方法卡关联、成长报告、跨周计划。
- 已知非本次引入的失败：`ChinLearningCoreTests` 中 2 个持久化用例（`testCompletedTaskAndPortfolioSurviveRepositoryReload`、`testNewMistakeRecordPersistsQuestionMetadataAndSurvivesReload`）在 `swift test`（macOS 目标）下共 12 条断言失败；用 `git stash` 回退题库改动后同样失败，属既有问题，待有 iOS 环境时复核。

Catalyst 编译已通过：

```bash
xcodebuild \
  -project ChinTop.xcodeproj \
  -scheme ChinTop \
  -destination 'platform=macOS,variant=Mac Catalyst,arch=arm64' \
  -configuration Debug \
  -derivedDataPath /private/tmp/chintop-toolbox-build \
  CODE_SIGNING_ALLOWED=NO \
  build
```

工程由以下命令生成：

```bash
xcodegen generate
```

当前机器没有可用的 iOS Simulator runtime，因此尚未完成真实 iPhone/iPad 界面验证；Catalyst 构建只能证明 SwiftUI 源码和链接通过，不能替代触控设备验收。

## 剩余任务（按优先级）

### P0：下次优先处理

1. **真实 iOS UI 验证**
   - 有可用 Simulator runtime 或连接设备后，检查 `NavigationSplitView`、工具箱搜索、方法卡跳转、任务保存、错题复盘和键盘输入。
   - 重点看 iPhone 窄屏、iPad 横屏、动态字体和深色模式。
   - 当前只能用 Catalyst 做编译验证，不要把 Catalyst 编译通过写成“iOS 已验收”。

2. **题库内容与来源审计**
   - 120 道题仍为“本地精选练习 · 来源待核验”标注。
   - 逐题第三方审校题干、选项、解析和知识点标签；不能把未核验内容包装成真实试题或名校真题。

### P1：产品价值增强

3. **增加开放式迁移任务**
   - 每项能力至少增加一组“原题方法 → 新情境应用”的任务。
   - 重点增加阅读证据、图表边界、口语表达、生活观察和跨文本比较。
   - 不以虚构自动评分替代学生表达；继续使用作品、自评和下一步计划沉淀证据。

4. **方法工具箱体验完善**
   - 显示当前能力筛选状态，而不是只显示“筛选”。
   - 增加“从当前能力继续练习”的明确入口。
   - 检查空结果、长标题、长示例和小屏幕布局。

5. **付费流程验收（本地配置已就绪）**
   - `ChinTopApp.storekit` 本地商品配置已挂载 scheme，Xcode 运行即可测试购买/恢复流程。
   - 上线前确认 App Store Connect 中的产品 ID、价格和本地化文案与代码一致，并做沙盒验收。
   - 未完成真实商品配置前，不要宣称支付流程已上线。

### P2：发布前质量

6. **可访问性与设备适配**
   - VoiceOver 标签、动态字体、颜色对比度、深色模式。
   - iPhone、iPad、Mac Catalyst 三种布局分别检查。
   - 长文本编辑、键盘遮挡和返回导航需要实际操作验证。

7. **清理与文档**
   - 评估是否继续保留未使用的 `ChinPromoView`，不要在没有产品决定前重新接入启动流程。
   - 为核心数据迁移、能力映射和本地存储补充简短开发说明。
   - 在代码结构稳定后再考虑拆分过大的 SwiftUI 文件，不做无关重构。

## 明天建议启动顺序

1. 先运行 `swift test`，确认 `ChinQuestionBankTests` 全绿（13 项），并留意 `ChinLearningCoreTests` 的既有失败。
2. 有 iOS Simulator runtime 或真机后优先做 P0-1 的真实 UI 验收。
3. 题库发布前做 P0-2 的逐题第三方审校。
4. 每个新增行为遵循 TDD：先写失败测试，再写最小实现，再跑完整测试。
5. 完成后重新运行 Catalyst 构建；如果仍无 iOS runtime，明确记录“未完成真实设备验收”。

## 关键文件

- 核心模型与业务逻辑：[ChinLearningCore.swift](ChinTopApp/Core/ChinLearningCore.swift)
- 题库数据层（535 题 + 33 个知识点目录）：[ChinQuestionBank.swift](ChinTopApp/Core/ChinQuestionBank.swift)
- 学习状态管理：[ChinLearningStore.swift](ChinTopApp/ChinLearningStore.swift)
- 学习相关界面：[ChinLearningViews.swift](ChinTopApp/ChinLearningViews.swift)
- 专题模块与练习界面：[ChinContent.swift](ChinTopApp/ChinContent.swift)
- 应用导航：[ChinTopApp.swift](ChinTopApp/ChinTopApp.swift)
- 付费流程：[ChinPurchaseManager.swift](ChinTopApp/ChinPurchaseManager.swift)、[ChinPaywallView.swift](ChinTopApp/ChinPaywallView.swift)
- 核心测试：[ChinLearningCoreTests.swift](Tests/ChinLearningCoreTests.swift)、[ChinQuestionBankTests.swift](Tests/ChinQuestionBankTests.swift)
