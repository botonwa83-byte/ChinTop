# ChinTop 分学段题库与结构优化设计

## 背景

ChinTop 面向小学高年级和初中学生，当前题目数据、题目组装逻辑和练习视图集中在 `ChinTopApp/ChinContent.swift`。现有题目没有年级、知识点 ID、重要性或难度字段；题目总量通过 `prefix(30)` 截断，规则生成题重复度较高；`ChinModule.practice(for:)` 的知识点参数没有真正参与筛选。当前年级只影响每日任务提示，不影响练习题集合。

二期目标是先优化题库结构，再注入小学和初中合计 120 道人工编写选择题，按学段和知识点重要性分布。学习闭环、四栏导航、StoreKit 付费边界和本地学习记录继续保留。

## 目标与非目标

### 目标

- 建立独立、可查询、可持续扩充的题库数据层。
- 让小学高年级和初中真正看到不同的题目集合。
- 为每道题建立稳定 ID、知识点 ID、重要性、难度和来源类型。
- 让专题知识点筛选只返回对应知识点的题目，并提供空结果状态。
- 注入 120 道人工编写题目：小学 60 道、初中 60 道。
- 保持旧本地快照可解码，新增学习记录字段向后兼容。
- 保持“本地精选练习/来源待核验”等诚实来源标注，不宣称真题、AI 批改或真实考试来源。

### 非目标

- 本期不引入网络题库、远程配置、SQLite 或内容管理后台。
- 本期不实现主观题自动评分。
- 本期不重写每日任务、作品库、错题复盘和成长报告的核心算法。
- 本期不改变完整解锁的 StoreKit 产品 ID 或付费政策。

## 题量与内容分布

总量为 120 道，每个题目属于一个学段和一个专题。题目分布如下：

| 学段 | 现代文阅读 | 文言文解码 | 古诗词鉴赏 | 考场作文升格 | 综合性学习与材料题 | 合计 |
|---|---:|---:|---:|---:|---:|---:|
| 小学高年级 | 18 | 6 | 10 | 14 | 12 | 60 |
| 初中 | 16 | 16 | 12 | 10 | 6 | 60 |
| 合计 | 34 | 22 | 22 | 24 | 18 | 120 |

分布原则：小学侧重阅读证据、规范表达、叙事写作和综合实践；初中增加文言实词/虚词/句式、古诗词表达技巧和更复杂的论证阅读。每个专题内部按 `core`（核心高频）、`supporting`（重要支撑）和 `extension`（迁移拓展）标记重要性，并按基础、进阶、挑战标记难度。数量配额和知识点清单写入题库数据层，测试校验总量和学段配额。

## 数据模型

### `ChinGradeLevel`

继续使用现有 `primary` 和 `middle` 枚举。题库查询必须显式接收学段，禁止默认把两个学段混合返回。

### `ChinKnowledgePoint`

新增稳定知识点模型：

- `id: String`：机器稳定 ID，例如 `reading.evidence`。
- `moduleID: String`：所属专题。
- `title: String`：面向学生显示的知识点名称。
- `grades: Set<ChinGradeLevel>`：覆盖学段。
- `importance: ChinQuestionImportance`：该知识点在本学段的默认重要性。

知识点目录按模块集中维护。模块现有 `points` 字符串继续用于展示兼容层，但练习筛选使用知识点 ID。

### `ChinQuestion`

新增题目模型，替代页面私有的 `ChinQuestionSeed`：

- `id: String`
- `moduleID: String`
- `grade: ChinGradeLevel`
- `knowledgePointID: String`
- `importance: ChinQuestionImportance`（`core`、`supporting`、`extension`）
- `difficulty: ChinQuestionDifficulty`（`foundation`、`developing`、`challenge`）
- `prompt: String`
- `choices: [String]`
- `answerIndex: Int`
- `explanation: String`
- `source: String`：每题必填的来源说明，例如“本地精选练习 · 来源待核验”。
- `sourceKind: ChinQuestionSourceKind`（`localCurated`、`pendingVerification`）

`ChinPractice` 作为练习视图模型继续存在，由 `ChinQuestion` 转换得到，保留 `answer` 字符串以兼容当前作答和错题记录流程。转换时对选项做稳定轮换时，必须同步计算答案文本，不能改变正确答案语义。

## 查询接口

新增 `ChinQuestionBank` 公开查询接口：

```swift
static func questions(
    moduleID: String? = nil,
    grade: ChinGradeLevel,
    knowledgePointID: String? = nil,
    importance: ChinQuestionImportance? = nil
) -> [ChinQuestion]

static func knowledgePoints(
    moduleID: String,
    grade: ChinGradeLevel
) -> [ChinKnowledgePoint]
```

结果保持数据声明顺序稳定。未知知识点返回空数组。`ChinModule.practice(for:grade:knowledgePointID:)` 只调用该查询接口，不再拼接或截断规则生成题。

练习页默认展示当前学段、当前专题的全部题目；知识点选择器传递知识点 ID。免费用户仍展示前 3 题，已解锁用户展示当前筛选结果的全部题目。显示文案改为动态数量，避免继续写死“完整 20 题”。

## 学习记录兼容

`ChinMistakeRecord` 增加可选字段：`gradeID`、`knowledgePointID`、`difficulty`。自定义 `Codable` 解码对旧快照缺失字段使用 `nil`，旧记录仍按 `moduleID` 和 `skill` 回退到现有能力映射。

`ChinLearningStore.recordPractice` 和 `ChinLearningRepository.recordPractice` 增加可选参数并向下传递。现有调用点可以使用默认值，旧数据无需迁移脚本。新记录保存题目元数据，为后续按学段/知识点统计留下接口，但本期成长报告仅保持当前能力维度展示。

## 文件边界

- 新建 `ChinTopApp/Core/ChinQuestionBank.swift`：题目枚举、知识点目录、120 道题目和查询接口。
- 修改 `ChinTopApp/ChinContent.swift`：移除题目私有种子与生成器；保留模块、练习视图和题目作答 UI；接入学段和知识点筛选。
- 修改 `ChinTopApp/Core/ChinLearningCore.swift`：增加题目元数据枚举和错题记录可选字段，保持 Codable 兼容。
- 修改 `ChinTopApp/ChinLearningStore.swift`：传递新增题目元数据。
- 修改 `Tests/ChinLearningCoreTests.swift`：增加题库配额、学段隔离、知识点筛选、元数据完整性和旧快照解码测试。
- 可新增 `Tests/ChinQuestionBankTests.swift`：仅测试题库数据层，不依赖 SwiftUI。

不把题目继续放回页面文件；不拆分现有学习视图，除非编译或测试证明需要。

## 测试与验收

### 数据层测试

- 总题数为 120。
- 小学和初中各 60 题。
- 五个模块的学段配额符合上表。
- 每题 ID 唯一，知识点 ID 存在且属于同一模块。
- `answerIndex` 在选项范围内，选项不少于 2 个，解析和来源字段非空。
- 小学查询不返回初中题，初中查询不返回小学题。
- 指定知识点查询结果全部匹配该知识点；未知知识点结果为空。
- 每个模块至少有一个 `core` 知识点和一个可查询题目。

### 兼容性测试

- 缺少新增错题字段的旧 JSON 可以正常解码。
- 新记录编码后包含新增字段；旧字段值保持不变。
- 题目转换和选项轮换后，答案文本仍指向原正确选项。

### 工程验证

- `swift test` 全部通过。
- Catalyst Debug 构建通过。
- 当前无 iOS Simulator runtime 时，明确记录未完成真实 iPhone/iPad 触控验收。

## 内容质量规则

- 每题只考一个主知识点，干扰项必须有明确错误原因。
- 解析至少说明正确依据或方法，不只重复正确选项。
- 小学题使用可理解的文本长度和表达支架；初中题允许更复杂的语境、术语和跨句推理。
- 题目来源统一标注为本地精选或来源待核验，不能写成真题、名校题或官方题库。
- 题目注入前先通过结构测试，再做逐题人工审校；数量达标不能替代内容审校。
