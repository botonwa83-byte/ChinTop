import SwiftUI

struct ChinModule: Identifiable, Hashable {
    let id: String; let title: String; let subtitle: String; let icon: String; let color: Color
    static let all = [
        ChinModule(id: "reading", title: "现代文阅读", subtitle: "小学高年级到初中 · 证据链、人物与主旨", icon: "book.pages", color: .blue),
        ChinModule(id: "classical", title: "文言文解码", subtitle: "实词、虚词、句式与翻译", icon: "scroll", color: .orange),
        ChinModule(id: "poetry", title: "古诗词鉴赏", subtitle: "意象、炼字与表达技巧", icon: "wind", color: .purple),
        ChinModule(id: "writing", title: "考场作文升格", subtitle: "审题、选材、结构与细节", icon: "pencil.and.outline", color: .pink),
        ChinModule(id: "integrated", title: "综合性学习与材料题", subtitle: "图表、新闻、口语与探究", icon: "rectangle.3.group", color: .green)
    ]

    /// 覆盖知识点与练习筛选器同源，统一来自题库目录。
    func knowledgePoints(grade: ChinGradeLevel) -> [ChinKnowledgePoint] {
        ChinQuestionBank.knowledgePoints(moduleID: id, grade: grade)
    }

    func questionCount(grade: ChinGradeLevel) -> Int {
        ChinQuestionBank.questions(moduleID: id, grade: grade).count
    }

    func practice(grade: ChinGradeLevel, knowledgePointID: String? = nil) -> [ChinPractice] {
        ChinQuestionBank.questions(moduleID: id, grade: grade, knowledgePointID: knowledgePointID).enumerated().map { index, q in
            let shift = index % q.choices.count
            let choices = Array(q.choices[shift...] + q.choices[..<shift])
            let pointTitle = ChinQuestionBank.knowledgePoint(id: q.knowledgePointID)?.title ?? q.knowledgePointID
            return ChinPractice(id: q.id, moduleID: id, grade: q.grade, knowledgePointID: q.knowledgePointID, difficulty: q.difficulty, point: pointTitle, prompt: q.prompt, choices: choices, answer: q.choices[q.answerIndex], explanation: q.explanation, skill: pointTitle, source: q.source)
        }
    }
}

struct ChinPractice: Identifiable, Hashable {
    let id: String
    let moduleID: String
    let grade: ChinGradeLevel
    let knowledgePointID: String
    let difficulty: ChinQuestionDifficulty
    let point: String
    let prompt: String
    let choices: [String]
    let answer: String
    let explanation: String
    let skill: String
    let source: String?

    var capabilityID: String {
        ChinCapability.capabilityID(knowledgePointID: knowledgePointID, moduleID: moduleID, skill: skill)
    }
}

struct ModuleView: View {
    let module: ChinModule
    @EnvironmentObject private var purchase: ChinPurchaseManager
    @EnvironmentObject private var learning: ChinLearningStore
    @State private var showPaywall = false

    private var tasks: [ChinDailyTask] {
        ChinDailyTaskCatalog.all.filter { $0.moduleID == module.id }
    }

    private var questionCount: Int {
        module.questionCount(grade: learning.grade)
    }

    /// 本模块在当前学段的知识点，按学习路径排好顺序（学生照着序号往下练即可）。
    private var orderedSteps: [ChinPathStep] {
        ChinLearningPath.steps(for: learning.grade).filter { $0.moduleID == module.id }
    }

    var body: some View {
        List {
            Section { Text(module.subtitle).foregroundStyle(.secondary) }
            Section("知识点 · 按顺序练") {
                ForEach(orderedSteps) { step in
                    NavigationLink {
                        ChinKnowledgePointPracticeView(step: step)
                    } label: {
                        HStack(spacing: 10) {
                            Text("\(step.order)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.blue, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(step.title).font(ChinFont.cardTitle)
                                Text("\(step.brief) · \(step.questionCount) 题")
                                    .font(ChinFont.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            Section("精选题目") {
                NavigationLink {
                    PracticeListView(module: module, grade: learning.grade, isUnlocked: purchase.isUnlocked, onUnlock: { showPaywall = true })
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        VStack(alignment: .leading) {
                            Text(purchase.isUnlocked ? "开始完整练习" : "免费试练 \(ChinQuestionBank.freeQuestionCount) 题")
                            Text(purchase.isUnlocked ? "\(learning.grade.title)题库共 \(questionCount) 题 · 逐题作答、解析与错题复盘" : "解锁后开放\(learning.grade.title)全部 \(questionCount) 题")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            Section("能力任务 · 学完知识点再做") {
                ForEach(tasks) { task in
                    NavigationLink {
                        ChinTaskView(task: task)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: ChinCapability.capability(for: task.capabilityID).icon)
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title).font(.headline)
                                Text(task.method).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            if !purchase.isUnlocked { Section { Button("解锁完整模块") { showPaywall = true }.buttonStyle(.borderedProminent) } }
        }
        .navigationTitle(module.title)
        .sheet(isPresented: $showPaywall) { ChinPaywallView() }
    }
}

private struct PracticeListView: View {
    let module: ChinModule; let grade: ChinGradeLevel; let isUnlocked: Bool; let onUnlock: () -> Void
    @State private var selectedKnowledgePointID: String?
    private var allQuestions: [ChinPractice] { module.practice(grade: grade, knowledgePointID: selectedKnowledgePointID) }
    private var questions: [ChinPractice] { Array(allQuestions.prefix(isUnlocked ? allQuestions.count : ChinQuestionBank.freeQuestionCount)) }
    var body: some View {
        List {
            Section {
                Picker("知识点", selection: $selectedKnowledgePointID) {
                    Text("全部知识点").tag(String?.none)
                    ForEach(ChinQuestionBank.knowledgePoints(moduleID: module.id, grade: grade)) { point in Text(point.title).tag(Optional(point.id)) }
                }
            }
            Section("精选练习 · \(questions.count) / \(allQuestions.count) 道") {
                if allQuestions.isEmpty { Text("这个知识点暂时没有练习").foregroundStyle(.secondary) }
                ForEach(questions) { q in
                    NavigationLink { ChinQuestionView(question: q) } label: {
                        VStack(alignment: .leading, spacing: 5) { Text(q.prompt).font(.headline).lineLimit(2); Text(q.source ?? q.skill).font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
            if !isUnlocked && allQuestions.count > ChinQuestionBank.freeQuestionCount { Section { Button("解锁完整题库") { onUnlock() }.buttonStyle(.borderedProminent) } }
        }.navigationTitle(module.title)
    }
}

struct ChinQuestionView: View {
    let question: ChinPractice
    @EnvironmentObject private var learning: ChinLearningStore
    @State private var selected: String?
    @State private var submitted = false
    @State private var didRecord = false

    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            Text(question.point).font(.caption).foregroundStyle(.secondary)
            Text(question.prompt).font(.title3.bold())
            ForEach(question.choices, id: \.self) { choice in Button { selected = choice } label: { HStack { Text(choice); Spacer(); if submitted && choice == question.answer { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) } }.padding().frame(maxWidth: .infinity, alignment: .leading).background(choiceBackground(choice), in: RoundedRectangle(cornerRadius: ChinRadius.pill)) }.buttonStyle(.plain).disabled(submitted) }
            if submitted {
                VStack(alignment: .leading, spacing: 8) {
                    Label(selected == question.answer ? "回答正确" : "这题未答对", systemImage: selected == question.answer ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(selected == question.answer ? .green : .red)
                    if selected != question.answer { Text("正确答案：\(question.answer)").fontWeight(.semibold) }
                    Text(question.explanation)
                    Text(selected == question.answer ? "继续保持：把这个方法带到下一题。" : "这道题已加入“错题复盘”，看懂依据后再试一次。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((selected == question.answer ? Color.green : Color.orange).opacity(0.12), in: RoundedRectangle(cornerRadius: ChinRadius.pill))
            }
            Button(submitted ? "再做一次" : "提交答案") {
                if submitted {
                    submitted = false
                    selected = nil
                    didRecord = false
                } else if let selected {
                    submitted = true
                    if !didRecord {
                        learning.recordPractice(question: question, selectedAnswer: selected, isCorrect: selected == question.answer)
                        didRecord = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selected == nil && !submitted)
        }.padding() }
    }
    private func choiceBackground(_ choice: String) -> Color {
        if !submitted { return selected == choice ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.08) }
        if choice == question.answer { return Color.green.opacity(0.18) }
        if choice == selected { return Color.red.opacity(0.14) }
        return Color.secondary.opacity(0.06)
    }
}
