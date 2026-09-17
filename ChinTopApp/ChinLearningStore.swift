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

    private func sync() {
        snapshot = repository.snapshot
    }
}
