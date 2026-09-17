import XCTest
// SwiftPM(ChinTopCore 模块) 与 Xcode 测试目标(Core 源码同模块编译) 双跑兼容
#if canImport(ChinTopCore)
@testable import ChinTopCore
#endif

final class ChinLearningPathTests: XCTestCase {

    /// 每个学段的路径必须覆盖该学段全部知识点：不漏、不重、不跨学段。
    func testPathCoversEveryKnowledgePointOfItsGrade() {
        for grade in ChinGradeLevel.allCases {
            let pathPoints = Set(ChinLearningPath.steps(for: grade).map(\.knowledgePointID))
            let catalogPoints = Set(ChinQuestionBank.knowledgePointCatalog.filter { $0.grades.contains(grade) }.map(\.id))
            XCTAssertEqual(pathPoints, catalogPoints, "\(grade.rawValue) 学习路径与知识点目录不一致")
        }
    }

    /// 学习顺序连续且唯一，学生看到的"第 N 步"不会跳号或重复。
    func testStepOrderIsContinuousAndUnique() {
        for grade in ChinGradeLevel.allCases {
            let orders = ChinLearningPath.steps(for: grade).map(\.order)
            XCTAssertEqual(orders, Array(1...orders.count), "\(grade.rawValue) 步骤序号应连续递增")
            let ids = ChinLearningPath.steps(for: grade).map(\.knowledgePointID)
            XCTAssertEqual(Set(ids).count, ids.count)
        }
    }

    /// 每一步都必须带得出练习题：知识点不能只是文字说明。
    func testEveryStepHasQuestions() {
        for grade in ChinGradeLevel.allCases {
            for step in ChinLearningPath.steps(for: grade) {
                XCTAssertGreaterThan(step.questionCount, 0, "\(step.knowledgePointID)@\(grade.rawValue) 没有配套练习")
                XCTAssertTrue(step.questions.allSatisfy { $0.knowledgePointID == step.knowledgePointID && $0.grade == grade })
            }
        }
    }

    /// 练习题按 基础 → 提高 → 挑战 递进，学生知道从易到难。
    func stepQuestionsAreSortedByDifficulty() throws {
        let step = try XCTUnwrap(ChinLearningPath.steps(for: .middle).first)
        let ranks = step.questions.map { q -> Int in
            switch q.difficulty {
            case .foundation: return 0
            case .developing: return 1
            case .challenge: return 2
            }
        }
        XCTAssertEqual(ranks, ranks.sorted())
    }

    /// 小学与初中知识点不混：初中专属考点（虚词、句式、翻译、议论文、材料探究）不出现在小学路径。
    func testGradeSpecificPointsAreNotMixed() {
        let primary = Set(ChinLearningPath.steps(for: .primary).map(\.knowledgePointID))
        let middleOnly: Set<String> = ["classical.function", "classical.sentence", "classical.translation", "classical.appreciation", "reading.argumentative", "writing.argument", "integrated.material"]
        XCTAssertTrue(primary.isDisjoint(with: middleOnly), "小学路径不应包含初中专属知识点")

        let middle = Set(ChinLearningPath.steps(for: .middle).map(\.knowledgePointID))
        let primaryOnly: Set<String> = ["reading.environment", "reading.strategy", "writing.language", "integrated.oral", "integrated.news", "integrated.activity"]
        XCTAssertTrue(middle.isDisjoint(with: primaryOnly), "初中路径不应包含小学专属知识点")
    }

    /// 每一步都有"考什么"和"练完能拿下什么"的说明，避免只剩方法名词。
    func testEveryStepExplainsWhatAndWhy() {
        for grade in ChinGradeLevel.allCases {
            for step in ChinLearningPath.steps(for: grade) {
                XCTAssertFalse(step.brief.trimmingCharacters(in: .whitespaces).isEmpty)
                XCTAssertFalse(step.goal.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    /// 下一步推荐：优先没练过的知识点；全练过后回到有待巩固的知识点。
    func testNextStepPrefersUnpracticedThenWeak() {
        let all = ChinLearningPath.steps(for: .middle)
        let first = ChinLearningPath.nextStep(for: .middle, practiced: [])
        XCTAssertEqual(first?.knowledgePointID, all.first?.knowledgePointID)

        let practicedAll = Set(all.map(\.knowledgePointID))
        let weak = Set([all[3].knowledgePointID])
        XCTAssertEqual(ChinLearningPath.nextStep(for: .middle, practiced: practicedAll, weakPoints: weak)?.knowledgePointID, all[3].knowledgePointID)
    }

    /// 知识点进度写入存档后可还原，且旧存档（没有该字段）能正常解码。
    func testKnowledgePointProgressPersistsAndOldSnapshotDecodes() throws {
        var snapshot = ChinLearningSnapshot()
        snapshot.recordPractice(
            questionID: "q1",
            moduleID: "reading",
            capabilityID: "evidence",
            gradeID: ChinGradeLevel.middle.rawValue,
            knowledgePointID: "reading.evidence",
            difficulty: ChinQuestionDifficulty.foundation.rawValue,
            skill: "证据与信息提取",
            prompt: "题干",
            selectedAnswer: "A",
            correctAnswer: "A",
            explanation: "解析",
            isCorrect: true,
            date: Date()
        )
        XCTAssertEqual(snapshot.knowledgePointProgress["reading.evidence"], 1)

        let data = try JSONEncoder().encode(snapshot)
        let restored = try JSONDecoder().decode(ChinLearningSnapshot.self, from: data)
        XCTAssertEqual(restored.knowledgePointProgress["reading.evidence"], 1)

        let legacy = """
        {"gradeID":"middle","completedTaskIDs":[],"completedTaskKeys":[],"portfolio":[],"mistakes":[],"practiceCount":2,"correctCount":1,"activityDates":[]}
        """
        let old = try JSONDecoder().decode(ChinLearningSnapshot.self, from: Data(legacy.utf8))
        XCTAssertTrue(old.knowledgePointProgress.isEmpty)
    }
}
