import SwiftUI

@MainActor
final class ChinLearningStore: ObservableObject {
    @Published private(set) var snapshot: ChinLearningSnapshot

    private let repository: ChinLearningRepository

    init(defaults: UserDefaults = .standard) {
        repository = ChinLearningRepository(defaults: defaults)
        snapshot = repository.snapshot
    }

    var grade: ChinGradeLevel {
        ChinGradeLevel(rawValue: snapshot.gradeID) ?? .middle
    }

    var todayTask: ChinDailyTask {
        ChinDailyTaskCatalog.task(grade: grade)
    }

    var learningReport: ChinLearningReport {
        snapshot.learningReport()
    }

    var weeklyPlan: ChinWeeklyPlan {
        ChinWeeklyPlan.make(snapshot: snapshot)
    }

    func setGrade(_ grade: ChinGradeLevel) {
        repository.setGrade(grade)
        sync()
    }

    func completeTask(_ taskID: String) {
        repository.completeTask(taskID)
        sync()
    }

    func recordPractice(
        question: ChinPractice,
        selectedAnswer: String,
        isCorrect: Bool
    ) {
        repository.recordPractice(
            questionID: question.id,
            moduleID: question.moduleID,
            capabilityID: question.capabilityID,
            gradeID: question.grade.rawValue,
            knowledgePointID: question.knowledgePointID,
            difficulty: question.difficulty.rawValue,
            skill: question.skill,
            prompt: question.prompt,
            selectedAnswer: selectedAnswer,
            correctAnswer: question.answer,
            explanation: question.explanation,
            isCorrect: isCorrect
        )
        sync()
    }

    func savePortfolio(
        task: ChinDailyTask,
        response: String,
        reflection: String,
        checklist: [String: Bool]
    ) {
        repository.savePortfolio(
            task: task,
            response: response,
            reflection: reflection,
            checklist: checklist
        )
        sync()
    }

    func resolveMistake(_ id: String) {
        repository.resolveMistake(id)
        sync()
    }

    func capabilityActivityCount(_ capabilityID: String) -> Int {
        snapshot.portfolio.filter { $0.capabilityID == capabilityID }.count
    }

    // MARK: - 学习路径进度

    /// 已经练过至少一个题的知识点。
    var practicedKnowledgePoints: Set<String> {
        Set(snapshot.knowledgePointProgress.keys)
    }

    func practicedCount(for knowledgePointID: String) -> Int {
        snapshot.knowledgePointProgress[knowledgePointID] ?? 0
    }

    /// 还有未消化错题的知识点（需要回头巩固）。
    var weakKnowledgePoints: Set<String> {
        Set(snapshot.unresolvedMistakes.compactMap(\.knowledgePointID))
    }

    /// 这一步是否算过关：练过题，且这个知识点没有未消化的错题。
    func isKnowledgePointPassed(_ knowledgePointID: String) -> Bool {
        practicedCount(for: knowledgePointID) > 0 && !weakKnowledgePoints.contains(knowledgePointID)
    }

    /// 下一步该学什么：优先第一个没练过的知识点，全部练过后回到有待巩固的知识点。
    var nextPathStep: ChinPathStep? {
        ChinLearningPath.nextStep(for: grade, practiced: practicedKnowledgePoints, weakPoints: weakKnowledgePoints)
    }

    private func sync() {
        snapshot = repository.snapshot
    }
}
