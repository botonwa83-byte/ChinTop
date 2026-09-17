# ChinTop 分学段题库与结构优化实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 将 ChinTop 重构为可按学段、专题和知识点查询的题库，并注入小学高年级 60 题、初中 60 题，共 120 道人工编写题目。

**Architecture:** 题目从 `ChinContent.swift` 拆到独立的核心数据层。`ChinQuestionBank` 维护知识点目录、题目元数据和查询接口；SwiftUI 练习页只消费查询结果。学习记录对新增题目元数据使用可选 Codable 字段，旧快照继续可读。

**Tech Stack:** Swift 5、SwiftUI、XCTest、Swift Package Manager、XcodeGen、StoreKit 2（仅保留现有购买流程）。

**Spec:** `docs/superpowers/specs/2026-09-11-chintop-graded-question-bank-design.md`

## Global Constraints

- 题目总量为 120，道小学高年级 60、初中 60。
- 分布固定为：小学现代文 18、文言文 6、古诗词 10、作文 14、综合 12；初中现代文 16、文言文 16、古诗词 12、作文 10、综合 6。
- 每题必须有稳定 ID、学段、专题、知识点 ID、重要性、难度、四个选项、答案、解析和来源说明。
- 来源只使用“本地精选练习 · 来源待核验”等诚实标注，不写成真题、名校题或官方题库。
- 每题只考一个主知识点；小学题提供易理解的语境，初中题允许更复杂的术语和推理。
- 每日任务、作品库、错题复盘、成长报告核心逻辑和 StoreKit 产品 ID 不改变。
- 免费练习继续展示前 3 题，已解锁用户展示当前筛选结果的全部题目；数量文案不得写死 20 题。
- 当前工作区没有 Git 元数据，无法执行 commit；每个任务使用 `swift test`、`git diff --check`（若 Git 可用）和构建命令验证。

---

### Task 1: 建立题目元数据模型与知识点目录

**Files:**
- Create: `ChinTopApp/Core/ChinQuestionBank.swift`
- Modify: `ChinTopApp/Core/ChinLearningCore.swift`
- Create: `Tests/ChinQuestionBankTests.swift`

**Interfaces:**
- Produces `ChinQuestionImportance`, `ChinQuestionDifficulty`, `ChinQuestionSourceKind`，均实现 `String, Codable, CaseIterable, Hashable`。
- Produces `ChinKnowledgePoint` with `id`, `moduleID`, `title`, `grades`, `importance`。
- Produces `ChinQuestion` with the spec fields and `source: String`。
- Produces `ChinQuestionBank.questions(moduleID:grade:knowledgePointID:importance:)` and `knowledgePoints(moduleID:grade:)`。

- [x] **Step 1: Write the failing tests**

```swift
func testQuestionMetadataAndKnowledgePointFiltering() {
    let points = ChinQuestionBank.knowledgePoints(moduleID: "reading", grade: .primary)
    XCTAssertFalse(points.isEmpty)
    let id = points[0].id
    let questions = ChinQuestionBank.questions(moduleID: "reading", grade: .primary, knowledgePointID: id)
    XCTAssertFalse(questions.isEmpty)
    XCTAssertTrue(questions.allSatisfy { $0.knowledgePointID == id && $0.grade == .primary })
}

func testUnknownKnowledgePointReturnsEmpty() {
    XCTAssertTrue(ChinQuestionBank.questions(moduleID: "reading", grade: .primary, knowledgePointID: "missing.point").isEmpty)
}
```

- [x] **Step 2: Run tests to verify they fail**

Run: `swift test --filter ChinQuestionBankTests/testQuestionMetadataAndKnowledgePointFiltering`
Expected: FAIL because the new question bank types and query methods do not exist.

- [x] **Step 3: Write the minimal implementation**

Define the three enums, `ChinKnowledgePoint`, `ChinQuestion`, and a `ChinQuestionBank` skeleton containing a small fixture question and one `reading` knowledge point. Filter by `moduleID`, exact `grade`, exact `knowledgePointID`, and optional `importance` in declaration order.

- [x] **Step 4: Run tests to verify they pass**

Run: `swift test --filter ChinQuestionBankTests`
Expected: PASS.

- [x] **Step 5: Inspect the diff**

Run: `git diff --check` when Git metadata is available; otherwise inspect the changed files for trailing whitespace and non-ASCII identifiers.

### Task 2: 迁移 `ChinPractice` 转换和题库配额验证

**Files:**
- Modify: `ChinTopApp/ChinContent.swift:1-48`
- Modify: `ChinTopApp/Core/ChinQuestionBank.swift`
- Modify: `Tests/ChinQuestionBankTests.swift`

**Interfaces:**
- `ChinModule.practice(for:grade:knowledgePointID:) -> [ChinPractice]` calls only `ChinQuestionBank.questions`.
- `ChinPractice` is constructed from `ChinQuestion`; its `answer` remains the correct answer string after option rotation.

- [x] **Step 1: Write the failing tests**

```swift
func testPracticeConversionPreservesAnswerAfterOptionRotation() {
    let practice = try! XCTUnwrap(ChinModule.all.first { $0.id == "reading" }?.practice(for: "", grade: .primary).first)
    XCTAssertTrue(practice.choices.contains(practice.answer))
}

func testModulePracticeUsesGradeAndKnowledgePoint() {
    let module = ChinModule.all.first { $0.id == "reading" }!
    let primary = module.practice(for: "", grade: .primary)
    let middle = module.practice(for: "", grade: .middle)
    XCTAssertTrue(primary.allSatisfy { $0.moduleID == "reading" })
    XCTAssertTrue(middle.allSatisfy { $0.moduleID == "reading" })
    XCTAssertNotEqual(Set(primary.map(\.id)), Set(middle.map(\.id)))
}
```

- [x] **Step 2: Run tests to verify they fail**

Run: `swift test --filter ChinQuestionBankTests/testModulePracticeUsesGradeAndKnowledgePoint`
Expected: FAIL because `practice(for:grade:)` is not defined and the old generator still supplies mixed questions.

- [x] **Step 3: Write the minimal implementation**

Remove `ChinQuestionSeed`, `verifiedQuestions`, `additionalQuestions`, `rawQuestions`, and `generatedQuestions` from `ChinContent.swift`. Add the grade-aware `practice` overload and convert each `ChinQuestion`, rotating choices by index only after storing the original answer text.

- [x] **Step 4: Add quota tests before full content injection**

```swift
func testQuestionBankHasDeclaredGradeAndModuleQuotas() {
    let expected: [String: Int] = [
        "primary-reading": 18, "primary-classical": 6, "primary-poetry": 10,
        "primary-writing": 14, "primary-integrated": 12,
        "middle-reading": 16, "middle-classical": 16, "middle-poetry": 12,
        "middle-writing": 10, "middle-integrated": 6
    ]
    for (key, count) in expected {
        let parts = key.split(separator: "-")
        let grade = parts[0] == "primary" ? ChinGradeLevel.primary : .middle
        XCTAssertEqual(ChinQuestionBank.questions(moduleID: String(parts[1]), grade: grade).count, count, key)
    }
}
```

- [x] **Step 5: Run tests**

Run: `swift test --filter ChinQuestionBankTests`
Expected: the conversion tests pass; the quota test remains red until Tasks 3–7 inject all 120 questions.

### Task 3: 注入现代文与文言文题目

**Files:**
- Modify: `ChinTopApp/Core/ChinQuestionBank.swift`
- Modify: `Tests/ChinQuestionBankTests.swift`

**Interfaces:**
- Adds 18 primary reading questions and 16 middle reading questions.
- Adds 6 primary classical questions and 16 middle classical questions.
- Adds knowledge point IDs covering evidence,人物、结构、说明文、议论文、实词、虚词、句式、翻译、断句、内容概括。

- [x] **Step 1: Add content assertions first**

```swift
func testReadingAndClassicalQuestionsHaveValidContent() {
    for grade in ChinGradeLevel.allCases {
        for module in ["reading", "classical"] {
            let questions = ChinQuestionBank.questions(moduleID: module, grade: grade)
            XCTAssertTrue(questions.allSatisfy { $0.choices.count == 4 && $0.answerIndex < $0.choices.count })
            XCTAssertTrue(questions.allSatisfy { !$0.prompt.isEmpty && !$0.explanation.isEmpty && !$0.source.isEmpty })
        }
    }
}
```

- [x] **Step 2: Run the focused test**

Run: `swift test --filter ChinQuestionBankTests/testReadingAndClassicalQuestionsHaveValidContent`
Expected: FAIL while the module entries are incomplete.

- [x] **Step 3: Add the 46 questions**

Use stable IDs `primary-reading-01` through `primary-reading-18`, `middle-reading-01` through `middle-reading-16`, and equivalent classical IDs. Assign each question one declared knowledge point, one importance tier, one difficulty, and source text `本地精选练习 · 来源待核验`. Keep primary prompts shorter and scaffolded; use contextual multi-step reasoning in middle prompts.

- [x] **Step 4: Run focused tests**

Run: `swift test --filter ChinQuestionBankTests/testReadingAndClassicalQuestionsHaveValidContent`
Expected: PASS.

### Task 4: 注入古诗词与作文题目

**Files:**
- Modify: `ChinTopApp/Core/ChinQuestionBank.swift`
- Modify: `Tests/ChinQuestionBankTests.swift`

**Interfaces:**
- Adds 10 primary poetry, 12 middle poetry, 14 primary writing, and 10 middle writing questions.
- Poetry knowledge points include image/atmosphere, key-word refinement, technique, emotion, comparison, and structure.
- Writing knowledge points include topic selection, detail, opening/ending, structure, application writing, revision, and material立意.

- [x] **Step 1: Add per-module count tests**

```swift
func testPoetryAndWritingQuotas() {
    XCTAssertEqual(ChinQuestionBank.questions(moduleID: "poetry", grade: .primary).count, 10)
    XCTAssertEqual(ChinQuestionBank.questions(moduleID: "poetry", grade: .middle).count, 12)
    XCTAssertEqual(ChinQuestionBank.questions(moduleID: "writing", grade: .primary).count, 14)
    XCTAssertEqual(ChinQuestionBank.questions(moduleID: "writing", grade: .middle).count, 10)
}
```

- [x] **Step 2: Run the focused test**

Run: `swift test --filter ChinQuestionBankTests/testPoetryAndWritingQuotas`
Expected: FAIL before the entries are present.

- [x] **Step 3: Add the 46 questions**

Use stable IDs by grade/module and keep every answer/explanation tied to the selected knowledge point. Primary poetry emphasizes literal scene, basic imagery and emotion; middle poetry adds technique comparison and structural effect. Primary writing emphasizes concrete events and expression; middle writing adds material composition and application formats.

- [x] **Step 4: Run focused tests**

Run: `swift test --filter ChinQuestionBankTests/testPoetryAndWritingQuotas`
Expected: PASS.

### Task 5: 注入综合性学习题目并完成 120 题校验

**Files:**
- Modify: `ChinTopApp/Core/ChinQuestionBank.swift`
- Modify: `Tests/ChinQuestionBankTests.swift`

**Interfaces:**
- Adds 12 primary integrated and 6 middle integrated questions.
- Knowledge points include information summary, chart reading, interview, oral communication, news, slogan, activity plan, punctuation, and cross-text comparison.

- [x] **Step 1: Add global integrity tests**

```swift
func testEntireBankIsUniqueAndInternallyConsistent() {
    let all = ChinQuestionBank.all
    XCTAssertEqual(all.count, 120)
    XCTAssertEqual(Set(all.map(\.id)).count, 120)
    XCTAssertTrue(all.allSatisfy { $0.answerIndex >= 0 && $0.answerIndex < $0.choices.count })
    XCTAssertTrue(all.allSatisfy { ChinQuestionBank.knowledgePoint(id: $0.knowledgePointID)?.moduleID == $0.moduleID })
    XCTAssertEqual(all.filter { $0.grade == .primary }.count, 60)
    XCTAssertEqual(all.filter { $0.grade == .middle }.count, 60)
}
```

- [x] **Step 2: Run the integrity test to verify it fails**

Run: `swift test --filter ChinQuestionBankTests/testEntireBankIsUniqueAndInternallyConsistent`
Expected: FAIL until the integrated questions and all metadata checks are complete.

- [x] **Step 3: Add the 18 integrated questions**

Use stable IDs `primary-integrated-01` through `primary-integrated-12` and `middle-integrated-01` through `middle-integrated-06`. Mark at least one core knowledge point in every module and include all source strings.

- [x] **Step 4: Run the complete data-layer suite**

Run: `swift test --filter ChinQuestionBankTests`
Expected: PASS with 120 questions and no duplicate IDs.

### Task 6: 接入年级和知识点筛选 UI

**Files:**
- Modify: `ChinTopApp/ChinContent.swift`
- Modify: `ChinTopApp/ChinLearningViews.swift` if navigation state needs to be passed
- Modify: `ChinTopApp/ChinTopApp.swift` for current grade environment only if required

**Interfaces:**
- `ModuleView` reads `learning.grade` and passes it to `PracticeListView`.
- `PracticeListView` owns `selectedKnowledgePointID: String?`, obtains points from `ChinQuestionBank.knowledgePoints(moduleID:grade:)`, and queries `module.practice(for:grade:knowledgePointID:)`.

- [x] **Step 1: Add a failing UI-facing core test**

```swift
func testKnowledgePointFilteringDoesNotLeakOtherPoints() {
    let module = ChinModule.all.first { $0.id == "writing" }!
    let point = ChinQuestionBank.knowledgePoints(moduleID: module.id, grade: .middle)[0]
    let filtered = module.practice(for: point.id, grade: .middle, knowledgePointID: point.id)
    XCTAssertTrue(filtered.allSatisfy { $0.point == point.title || $0.skill == point.title })
}
```

- [x] **Step 2: Implement the filter control**

Add a `Picker` or menu above the question list with an “全部知识点” option and the grade-specific knowledge points. Use the knowledge point ID for selection, never the display title. Show a clear empty state when a query returns no questions.

- [x] **Step 3: Update dynamic counts and grade behavior**

Replace “完整 20 题” with `题库共 (questions.count) 题` and pass the current grade from `ChinLearningStore`. Preserve the free prefix of 3 after filtering, and keep the existing paywall callback.

- [x] **Step 4: Build and inspect**

Run: `xcodegen generate` then Catalyst build. Expected: no SwiftUI type errors; grade switching produces different question IDs.

### Task 7: 将题目元数据写入错题记录并兼容旧快照

**Files:**
- Modify: `ChinTopApp/Core/ChinLearningCore.swift`
- Modify: `ChinTopApp/ChinLearningStore.swift`
- Modify: `ChinTopApp/ChinContent.swift`
- Modify: `Tests/ChinLearningCoreTests.swift`

**Interfaces:**
- `ChinMistakeRecord` adds optional `gradeID`, `knowledgePointID`, `difficulty`.
- `ChinLearningRepository.recordPractice` and `ChinLearningStore.recordPractice` add matching optional parameters with `nil` defaults.

- [x] **Step 1: Write the failing compatibility test**

```swift
func testOldMistakeSnapshotDecodesWithoutQuestionMetadata() throws {
    let json = """
    {"id":"old-1","questionID":"old-1","moduleID":"reading","skill":"人物形象","prompt":"题目","selectedAnswer":"A","correctAnswer":"B","explanation":"依据","reviewCount":0,"isResolved":false,"lastAttemptAt":0}
    """.data(using: .utf8)!
    let record = try JSONDecoder().decode(ChinMistakeRecord.self, from: json)
    XCTAssertNil(record.gradeID)
    XCTAssertNil(record.knowledgePointID)
    XCTAssertNil(record.difficulty)
}
```

- [x] **Step 2: Run the test to verify it fails**

Run: `swift test --filter ChinLearningCoreTests/testOldMistakeSnapshotDecodesWithoutQuestionMetadata`
Expected: FAIL because the optional metadata properties do not exist.

- [x] **Step 3: Implement compatible fields and propagation**

Add optional Codable fields with `decodeIfPresent`, keep existing defaults, pass `question.grade.rawValue`, `question.knowledgePointID`, and `question.difficulty.rawValue` from `ChinQuestionView`, and leave old callers valid.

- [x] **Step 4: Add new-record assertions**

Record a wrong `ChinPractice` and assert the saved mistake contains the grade, knowledge point and difficulty values while existing module, skill, answer and explanation remain unchanged.

- [x] **Step 5: Run all core tests**

Run: `swift test`
Expected: all existing and new tests pass.

### Task 8: 完成结构验收、内容审校和工程验证

**Files:**
- Modify: `ChinTopApp/ChinContent.swift` only for final copy/count fixes
- Modify: `MEMORY.md` with the completed architecture and validation evidence
- Modify: `docs/superpowers/specs/2026-09-11-chintop-graded-question-bank-design.md` only if implementation decisions materially differ

**Interfaces:**
- Final public behavior is the query API and 120-question bank from Tasks 1–7.

- [x] **Step 1: Run all automated checks**

Run:

```bash
swift test
xcodegen generate
xcodebuild -project ChinTop.xcodeproj -scheme ChinTop \
  -destination 'platform=macOS,variant=Mac Catalyst,arch=arm64' \
  -configuration Debug -derivedDataPath /private/tmp/chintop-question-bank-build \
  CODE_SIGNING_ALLOWED=NO build
```

Expected: all tests pass and Catalyst build ends with `BUILD SUCCEEDED`.

- [x] **Step 2: Run static content checks**

Verify no `prefix(30)`, `generatedQuestions`, or “完整 20 题” remains in the active question flow. Verify every module has primary and middle results and at least one core knowledge point.

- [x] **Step 3: Perform manual content audit**

Review every question for one-to-one knowledge-point alignment, exactly one best answer, plausible distractors, explanation evidence, grade-appropriate language, and honest source text. Record any rejected item before claiming the 120-question quota.

- [x] **Step 4: Update project memory**

Record the final question totals, query API, compatibility behavior, test command results, and the limitation that real iOS device/simulator UI validation remains pending when no runtime is available.


---

## 进度记录（2026-09-11）

**中断点定位**：Task 1–2、6 的骨架已完成，但 Task 3–5 的 120 道人工题从未真正注入——`ChinQuestionBank.buildAll()` 用模板批量生成 120 道题（同一知识点下题干、选项、答案完全相同），测试只校验结构所以全绿；约 110 道真正的人工题滞留在 `ChinContent.swift` 的死代码 `ChinLegacyQuestionBank` 中未接入。

**本次修复**：
1. 题库内容重做：迁移 98 道人工题 + 新写 22 道，共 120 道（小学 60 / 初中 60，配额与 spec 一致），删除模板生成器与 `ChinLegacyQuestionBank` 死代码。
2. 知识点目录扩充为 33 个细粒度知识点（含学段覆盖声明），模块"覆盖知识点"与练习筛选器统一从题库目录取数（删除 `ChinModule.points` 重复清单）。
3. 错题元数据链路打通：`recordPractice`（Snapshot/Repository/Store）传递 `gradeID`/`knowledgePointID`/`difficulty`，旧记录再次作答时同步更新；`ChinMistakeRecord` 相应字段改为 `var`。
4. 能力映射改为知识点 ID 表驱动（33 条映射），旧数据无知识点 ID 时回退原中文关键词匹配。
5. UI 文案自洽：模块页"题库共 120 题"改为按当前学段+模块动态计数。

**验证结果**：
- `swift test`：24 项测试全部通过（新增题干唯一、选项去重、知识点-学段覆盖、来源诚信、能力映射有效性、元数据落库并重载等测试）。
- `xcodegen generate` + Catalyst Debug 构建：BUILD SUCCEEDED。
- 静态检查：无 `prefix(30)`、`generatedQuestions`、"完整 20 题"残留；题库恰为 120 条人工条目。

**遗留**：
- 真实 iPhone/iPad 触控验收仍未做（本机无 iOS Simulator runtime），Catalyst 构建不能替代。
- 题目来源仍标注"本地精选练习 · 来源待核验"，发布前需逐题第三方审校。
- 无 Git 元数据，无法 commit。

## 进度记录（2026-09-11 下午·权重扩充）

- 应需求按重要性权重扩充题库：每个知识点在其覆盖学段内 core ≥ 4、supporting ≥ 3、extension ≥ 2。
- 分三批填充 67 道人工题：批 1 现代文阅读+文言文 29、批 2 古诗词+作文 24、批 3 综合性学习 14。题库总量 120 → 187（小学 92、初中 95）。
- 测试从"写死 120 配额"改为权重断言（`testQuestionCountsMatchImportanceWeights`）+ 学段总量下限，后续加题不再受固定配额限制。
- 验证：`swift test` 26 项全绿；Catalyst Debug 构建 BUILD SUCCEEDED；题干唯一/选项去重/来源诚信等测试同步覆盖新增 67 题。

## 进度记录（2026-09-11 下午·第四轮扩充 +120）

- 应需求再扩充 120 题：按每个"模块×学段"区块均衡 +12 的方案，分三批写入——批 4 阅读+文言 48、批 5 古诗词+作文 48、批 6 综合 24。
- 题库总量 187 → 307（小学 152、初中 155），33 个知识点在两学段继续全覆盖，题干唯一/选项去重/来源诚信测试同步覆盖新增题目。
- 修复一处编译错误：middle-writing-31 选项字符串引号未闭合（中文引号混入 ASCII 引号序列），改为纯文本选项后配平。
- 验证：`swift test` 26 项全绿；xcodegen + Catalyst Debug 构建 BUILD SUCCEEDED；审计确认恰为 307 条人工条目、无模板残留。
