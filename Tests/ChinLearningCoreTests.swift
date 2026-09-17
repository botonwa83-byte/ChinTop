import XCTest
// SwiftPM(ChinTopCore 模块) 与 Xcode 测试目标(Core 源码同模块编译) 双跑兼容
#if canImport(ChinTopCore)
@testable import ChinTopCore
#endif

final class ChinLearningCoreTests: XCTestCase {
    func testWrongPracticeCreatesReviewRecordAndTracksAccuracy() {
        let defaults = makeDefaults()
        let repository = ChinLearningRepository(defaults: defaults)
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        repository.recordPractice(
            questionID: "reading-1",
            moduleID: "reading",
            skill: "人物形象",
            prompt: "这段文字表现了人物怎样的品质？",
            selectedAnswer: "胆小怕事",
            correctAnswer: "乐于助人",
            explanation: "行动细节是判断人物品质的证据。",
            isCorrect: false,
            date: date
        )

        XCTAssertEqual(repository.snapshot.practiceCount, 1)
        XCTAssertEqual(repository.snapshot.correctCount, 0)
        XCTAssertEqual(repository.snapshot.mistakes.count, 1)
        XCTAssertEqual(repository.snapshot.mistakes.first?.questionID, "reading-1")
        XCTAssertEqual(repository.snapshot.mistakes.first?.reviewCount, 0)
    }

    func testOldMistakeSnapshotDecodesWithoutQuestionMetadata() throws {
        let json = "{\"id\":\"old-1\",\"questionID\":\"old-1\",\"moduleID\":\"reading\",\"skill\":\"人物形象\",\"prompt\":\"题目\",\"selectedAnswer\":\"A\",\"correctAnswer\":\"B\",\"explanation\":\"依据\",\"reviewCount\":0,\"isResolved\":false,\"lastAttemptAt\":0}".data(using: .utf8)!
        let record = try JSONDecoder().decode(ChinMistakeRecord.self, from: json)
        XCTAssertNil(record.gradeID)
        XCTAssertNil(record.knowledgePointID)
        XCTAssertNil(record.difficulty)
    }

    func testCompletedTaskAndPortfolioSurviveRepositoryReload() {
        let defaults = makeDefaults()
        let repository = ChinLearningRepository(defaults: defaults)
        let task = ChinDailyTaskCatalog.all[0]
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        repository.completeTask(task.id, date: date)
        repository.savePortfolio(
            task: task,
            response: "我先找出人物做了什么，再用动作细节说明他的品质。",
            reflection: "下次先圈出证据，再组织答案。",
            checklist: ["有文本证据": true, "观点说清楚": true, "语言完整": false],
            date: date
        )

        let reloaded = ChinLearningRepository(defaults: defaults)

        XCTAssertTrue(reloaded.snapshot.completedTaskIDs.contains(task.id))
        XCTAssertEqual(reloaded.snapshot.portfolio.count, 1)
        XCTAssertEqual(reloaded.snapshot.portfolio.first?.response, "我先找出人物做了什么，再用动作细节说明他的品质。")
        XCTAssertEqual(reloaded.snapshot.portfolio.first?.reflection, "下次先圈出证据，再组织答案。")
        XCTAssertEqual(reloaded.snapshot.activityDates.count, 1)
    }

    func testPrimaryTaskAddsAConcreteExpressionScaffold() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let task = ChinDailyTaskCatalog.task(for: date, grade: .primary)

        XCTAssertTrue(task.method.contains("先说后写"))
        XCTAssertTrue(task.challenge.contains("先列出两个关键词"))
    }

    func testLearningReportExplainsNextStepFromRecordedEvidence() throws {
        let defaults = makeDefaults()
        let repository = ChinLearningRepository(defaults: defaults)
        let task = ChinDailyTaskCatalog.all[0]
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        repository.savePortfolio(
            task: task,
            response: "我找到了动作证据，并写出了人物品质。",
            reflection: "下次补充结果。",
            checklist: ["有文本证据": true, "观点说清楚": true, "语言完整": true],
            date: date
        )
        repository.recordPractice(
            questionID: "reading-review",
            moduleID: task.moduleID,
            skill: task.title,
            prompt: "请说明人物品质。",
            selectedAnswer: "只写了结论",
            correctAnswer: "结合动作说明品质",
            explanation: "观点需要证据支持。",
            isCorrect: false,
            date: date
        )

        let report = repository.snapshot.learningReport(now: date)
        let evidence = try XCTUnwrap(report.capabilities.first(where: { $0.capabilityID == task.capabilityID }))

        XCTAssertEqual(report.portfolioCount, 1)
        XCTAssertEqual(report.unresolvedMistakeCount, 1)
        XCTAssertEqual(evidence.status, .needsReview)
        XCTAssertTrue(evidence.nextAction.contains("复盘"))
        XCTAssertTrue(report.headline.contains("待复盘"))
    }

    func testLearningReportUsesPracticeCapabilityWhenMistakeIsMoreSpecificThanModule() throws {
        let defaults = makeDefaults()
        let repository = ChinLearningRepository(defaults: defaults)
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        repository.recordPractice(
            questionID: "reading-sentence",
            moduleID: "reading",
            capabilityID: "expression",
            skill: "句子赏析",
            prompt: "赏析句子的表达效果。",
            selectedAnswer: "只写了生动形象",
            correctAnswer: "结合修辞和语境说明效果",
            explanation: "表达效果需要具体到手法和语境。",
            isCorrect: false,
            date: date
        )

        let report = repository.snapshot.learningReport(now: date)
        let expression = try XCTUnwrap(report.capabilities.first(where: { $0.capabilityID == "expression" }))
        let evidence = try XCTUnwrap(report.capabilities.first(where: { $0.capabilityID == "evidence" }))

        XCTAssertEqual(expression.status, .needsReview)
        XCTAssertEqual(evidence.status, .notStarted)
    }

    func testPracticeSkillMappingAssignsARelevantCapability() {
        XCTAssertEqual(
            ChinCapability.capabilityID(moduleID: "reading", skill: "句子赏析"),
            "expression"
        )
        XCTAssertEqual(
            ChinCapability.capabilityID(moduleID: "writing", skill: "细节描写"),
            "creation"
        )
        XCTAssertEqual(
            ChinCapability.capabilityID(moduleID: "classical", skill: "实词"),
            "reasoning"
        )
    }

    func testWeeklyPlanCoversSevenDatesAndReflectsCompletedTasks() throws {
        let calendar = makeCalendar()
        let monday = date(year: 2026, month: 9, day: 7, calendar: calendar)
        var snapshot = ChinLearningSnapshot()
        let firstTask = ChinDailyTaskCatalog.task(for: monday, calendar: calendar)
        snapshot.completeTask(firstTask.id, date: monday, calendar: calendar)

        let plan = ChinWeeklyPlan.make(for: monday, snapshot: snapshot, calendar: calendar)

        XCTAssertEqual(plan.days.count, 7)
        XCTAssertEqual(Set(plan.days.map(\.taskID)).count, 7)
        XCTAssertTrue(plan.days.first?.isCompleted == true)
        XCTAssertEqual(plan.completedCount, 1)
        XCTAssertEqual(plan.startDate, monday)
    }

    func testWeeklyPlanDoesNotCarryCompletionIntoARepeatTaskOnAnotherDate() {
        let calendar = makeCalendar()
        let monday = date(year: 2026, month: 9, day: 7, calendar: calendar)
        let repeatedTaskDate = date(year: 2026, month: 11, day: 2, calendar: calendar)
        var snapshot = ChinLearningSnapshot()
        let firstTask = ChinDailyTaskCatalog.task(for: monday, calendar: calendar)

        snapshot.completeTask(firstTask.id, date: monday, calendar: calendar)

        let futurePlan = ChinWeeklyPlan.make(
            for: repeatedTaskDate,
            snapshot: snapshot,
            calendar: calendar
        )

        XCTAssertEqual(futurePlan.days.first?.taskID, firstTask.id)
        XCTAssertFalse(futurePlan.days.first?.isCompleted == true)
    }

    func testMethodCardCatalogCoversEveryCapabilityAndLinksToTasks() {
        let cards = ChinMethodCardCatalog.all

        XCTAssertGreaterThanOrEqual(cards.count, 10)
        XCTAssertEqual(Set(cards.map(\.capabilityID)), Set(ChinCapability.all.map(\.id)))
        XCTAssertTrue(cards.allSatisfy { card in
            guard let taskID = card.taskID else { return false }
            return ChinDailyTaskCatalog.all.contains(where: { $0.id == taskID })
        })
    }

    func testMethodCardSearchMatchesContentAndCapability() {
        let evidenceCards = ChinMethodCardCatalog.search(query: "证据", capabilityID: "evidence")
        let writingCards = ChinMethodCardCatalog.search(query: "", capabilityID: "creation")

        XCTAssertFalse(evidenceCards.isEmpty)
        XCTAssertTrue(evidenceCards.allSatisfy { $0.capabilityID == "evidence" })
        XCTAssertFalse(writingCards.isEmpty)
        XCTAssertTrue(writingCards.allSatisfy { $0.capabilityID == "creation" })
    }

    func testEveryDailyTaskCanOpenItsRelatedMethodCard() {
        for task in ChinDailyTaskCatalog.all {
            let card = ChinMethodCardCatalog.card(forTaskID: task.id)
            XCTAssertEqual(card?.taskID, task.id, "任务 \(task.id) 应该关联一张方法卡")
            XCTAssertEqual(card?.capabilityID, task.capabilityID)
        }
    }

    func testNewMistakeRecordPersistsQuestionMetadataAndSurvivesReload() {
        let defaults = makeDefaults()
        let repository = ChinLearningRepository(defaults: defaults)
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        repository.recordPractice(
            questionID: "middle-classical-04",
            moduleID: "classical",
            capabilityID: "reasoning",
            gradeID: ChinGradeLevel.middle.rawValue,
            knowledgePointID: "classical.function",
            difficulty: ChinQuestionDifficulty.developing.rawValue,
            skill: "虚词",
            prompt: "“醒能述以文者”中“以”的意思是？",
            selectedAnswer: "因为",
            correctAnswer: "把、用",
            explanation: "‘以’为介词‘用’。",
            isCorrect: false,
            date: date
        )

        let reloaded = ChinLearningRepository(defaults: defaults)
        let mistake = reloaded.snapshot.mistakes.first

        XCTAssertEqual(mistake?.gradeID, "middle")
        XCTAssertEqual(mistake?.knowledgePointID, "classical.function")
        XCTAssertEqual(mistake?.difficulty, "developing")
        XCTAssertEqual(mistake?.moduleID, "classical")
        XCTAssertEqual(mistake?.correctAnswer, "把、用")

        // 再次作答（答对）时元数据保持，状态转为已复盘
        reloaded.recordPractice(
            questionID: "middle-classical-04",
            moduleID: "classical",
            capabilityID: "reasoning",
            gradeID: ChinGradeLevel.middle.rawValue,
            knowledgePointID: "classical.function",
            difficulty: ChinQuestionDifficulty.developing.rawValue,
            skill: "虚词",
            prompt: "“醒能述以文者”中“以”的意思是？",
            selectedAnswer: "把、用",
            correctAnswer: "把、用",
            explanation: "‘以’为介词‘用’。",
            isCorrect: true,
            date: date
        )

        let updated = reloaded.snapshot.mistakes.first
        XCTAssertEqual(updated?.knowledgePointID, "classical.function")
        XCTAssertTrue(updated?.isResolved == true)
    }

    func testKnowledgePointMappingFallsBackToLegacySkillMatching() {
        XCTAssertEqual(
            ChinCapability.capabilityID(knowledgePointID: "reading.language", moduleID: "reading", skill: "任意"),
            "expression"
        )
        XCTAssertEqual(
            ChinCapability.capabilityID(knowledgePointID: nil, moduleID: "reading", skill: "句子赏析"),
            "expression"
        )
        XCTAssertEqual(
            ChinCapability.capabilityID(knowledgePointID: "unknown.point", moduleID: "writing", skill: "细节"),
            "creation"
        )
    }

    func testOldSnapshotWithoutCompletedTaskKeysDecodesAndRewritesNewFields() throws {
        let json = "{\"gradeID\":\"primary\",\"completedTaskIDs\":[\"reading-evidence-chain\"],\"portfolio\":[],\"mistakes\":[],\"practiceCount\":2,\"correctCount\":1,\"activityDates\":[\"2026-09-10\"]}".data(using: .utf8)!
        let snapshot = try JSONDecoder().decode(ChinLearningSnapshot.self, from: json)

        XCTAssertEqual(snapshot.gradeID, "primary")
        XCTAssertEqual(snapshot.completedTaskIDs, ["reading-evidence-chain"])
        XCTAssertTrue(snapshot.completedTaskKeys.isEmpty)
        XCTAssertEqual(snapshot.practiceCount, 2)

        // 重新保存后新字段会被写入，旧字段值保持不变
        let data = try JSONEncoder().encode(snapshot)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(object["completedTaskKeys"])
        XCTAssertEqual(object["gradeID"] as? String, "primary")
        XCTAssertEqual(object["practiceCount"] as? Int, 2)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "ChinTopCoreTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(year: Int, month: Int, day: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
