import XCTest
// SwiftPM(ChinTopCore 模块) 与 Xcode 测试目标(Core 源码同模块编译) 双跑兼容
#if canImport(ChinTopCore)
@testable import ChinTopCore
#endif

final class ChinQuestionBankTests: XCTestCase {
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

    // 权重模型：每个知识点在其覆盖学段内 core ≥ 4、supporting ≥ 3、extension ≥ 2
    func testQuestionCountsMatchImportanceWeights() {
        for point in ChinQuestionBank.knowledgePointCatalog {
            let target = ChinQuestionBank.targetCount(importance: point.importance)
            for grade in point.grades {
                let count = ChinQuestionBank.questions(moduleID: point.moduleID, grade: grade, knowledgePointID: point.id).count
                XCTAssertGreaterThanOrEqual(count, target, "\(point.id)@\(grade.rawValue) 应有≥\(target)题，实际\(count)")
            }
        }
    }

    func testGradeTotalsMeetWeightModel() {
        XCTAssertGreaterThanOrEqual(ChinQuestionBank.all.filter { $0.grade == .primary }.count, 198)
        XCTAssertGreaterThanOrEqual(ChinQuestionBank.all.filter { $0.grade == .middle }.count, 220)
    }

    func testEntireBankIsUniqueAndInternallyConsistent() {
        let all = ChinQuestionBank.all
        XCTAssertGreaterThanOrEqual(all.count, 420)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
        XCTAssertTrue(all.allSatisfy { $0.answerIndex >= 0 && $0.answerIndex < $0.choices.count })
        XCTAssertTrue(all.allSatisfy { ChinQuestionBank.knowledgePoint(id: $0.knowledgePointID)?.moduleID == $0.moduleID })
    }

    // 内容质量：题干必须唯一，防止"模板换编号"式假题
    func testPromptsAreUnique() {
        let all = ChinQuestionBank.all
        XCTAssertEqual(Set(all.map(\.prompt)).count, all.count, "存在重复题干，疑似模板生成题")
    }

    // 内容质量：每题选项互不相同，且至少 2 个
    func testChoicesAreDistinctWithinEachQuestion() {
        for q in ChinQuestionBank.all {
            XCTAssertGreaterThanOrEqual(q.choices.count, 2, q.id)
            XCTAssertEqual(Set(q.choices).count, q.choices.count, "\(q.id) 存在重复选项")
            XCTAssertFalse(q.prompt.isEmpty, q.id)
            XCTAssertFalse(q.explanation.isEmpty, q.id)
        }
    }

    // 自洽性：目录中声明覆盖某学段的知识点，必须在该学段至少有一道题
    func testEveryListedKnowledgePointHasQuestionsForDeclaredGrades() {
        for point in ChinQuestionBank.knowledgePointCatalog {
            for grade in point.grades {
                let questions = ChinQuestionBank.questions(moduleID: point.moduleID, grade: grade, knowledgePointID: point.id)
                XCTAssertFalse(questions.isEmpty, "\(point.id) 声明覆盖 \(grade.rawValue) 但没有题目")
            }
        }
    }

    // 内容诚信：来源必须诚实标注，不得宣称真题/名校/官方
    func testSourcesUseHonestLabels() {
        let forbidden = ["真题", "名校", "官方题库", "押题"]
        for q in ChinQuestionBank.all {
            XCTAssertFalse(q.source.isEmpty, q.id)
            for word in forbidden {
                XCTAssertFalse(q.source.contains(word), "\(q.id) 来源含违禁标注: \(word)")
                XCTAssertFalse(q.prompt.contains(word), "\(q.id) 题干含违禁标注: \(word)")
            }
        }
    }

    // 能力映射：目录中每个知识点都能映射到有效能力
    func testEveryKnowledgePointMapsToAValidCapability() {
        let validIDs = Set(ChinCapability.all.map(\.id))
        for point in ChinQuestionBank.knowledgePointCatalog {
            let mapped = ChinCapability.capabilityID(knowledgePointID: point.id, moduleID: point.moduleID, skill: point.title)
            XCTAssertTrue(validIDs.contains(mapped), "\(point.id) 映射到无效能力 \(mapped)")
        }
    }

    // 学段隔离：小学查询不得返回初中题，反之亦然
    func testGradeQueriesAreIsolated() {
        for module in ["reading", "classical", "poetry", "writing", "integrated"] {
            XCTAssertTrue(ChinQuestionBank.questions(moduleID: module, grade: .primary).allSatisfy { $0.grade == .primary })
            XCTAssertTrue(ChinQuestionBank.questions(moduleID: module, grade: .middle).allSatisfy { $0.grade == .middle })
        }
    }

    // 免费档守门：内购划线常量必须与题库供给匹配，扩内容时不得打乱前 N 题
    func testFreeTierPolicy() {
        let free = ChinQuestionBank.freeQuestionCount
        XCTAssertGreaterThan(free, 0)
        XCTAssertLessThanOrEqual(free, 5, "免费档不宜过大，否则失去转化钩子")
        for module in ["reading", "classical", "poetry", "writing", "integrated"] {
            for grade in ChinGradeLevel.allCases {
                let count = ChinQuestionBank.questions(moduleID: module, grade: grade).count
                XCTAssertGreaterThanOrEqual(count, free, "\(module)/\(grade) 免费档题目不足")
                XCTAssertGreaterThan(count, free, "\(module)/\(grade) 免费档之外应有付费内容")
            }
        }
    }

    // 批次接线守门：曾出现 batch4/5/6 已定义却未并入 all，付费用户只能看到约六成题目
    func testAllBatchesAreWiredIntoBank() {
        XCTAssertGreaterThanOrEqual(ChinQuestionBank.all.count, 420, "题库总量应覆盖五轮扩充后的 423 道")
    }
}
