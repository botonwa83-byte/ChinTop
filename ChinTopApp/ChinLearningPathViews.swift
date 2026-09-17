import SwiftUI

/// 学习路径总览：按学段列出「先学什么、后学什么」，每一步都能直接点进去做题。
struct ChinLearningPathView: View {
    @EnvironmentObject private var learning: ChinLearningStore

    private var stages: [ChinPathStage] { ChinLearningPath.stages(for: learning.grade) }
    private var steps: [ChinPathStep] { stages.flatMap(\.steps) }
    private var passedCount: Int { steps.filter { learning.isKnowledgePointPassed($0.knowledgePointID) }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChinSpacing.lg) {
                header
                ForEach(stages) { stage in
                    stageSection(stage)
                }
            }
            .padding(ChinSpacing.lg)
            .chinReadableWidth()
        }
        .background(Color.chinBackground.ignoresSafeArea())
        .navigationTitle("\(learning.grade.title)学习路径")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("按顺序练，不用自己挑")
                .font(.title2.bold())
            Text("\(learning.grade.title)共 \(steps.count) 个知识点、\(steps.reduce(0) { $0 + $1.questionCount }) 道配套练习。已过关 \(passedCount) / \(steps.count)，从第一个没练过的知识点开始就行。")
                .font(ChinFont.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chinCardSurface()
    }

    private func stageSection(_ stage: ChinPathStage) -> some View {
        VStack(alignment: .leading, spacing: ChinSpacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: ChinSpacing.sm) {
                Image(systemName: stage.icon)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 3) {
                    Text(stage.title).font(ChinFont.sectionTitle)
                    Text(stage.subtitle).font(ChinFont.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(stage.questionCount) 题")
                    .font(ChinFont.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(stage.steps) { step in
                NavigationLink {
                    ChinKnowledgePointPracticeView(step: step)
                } label: {
                    ChinPathStepRow(step: step)
                }
                .buttonStyle(.plain)
            }
        }
        .chinCardSurface()
    }
}

private struct ChinPathStepRow: View {
    let step: ChinPathStep
    @EnvironmentObject private var learning: ChinLearningStore

    var body: some View {
        HStack(alignment: .top, spacing: ChinSpacing.md) {
            Text("\(step.order)")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(statusColor, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(step.title).font(ChinFont.cardTitle)
                    Spacer()
                    statusLabel
                }
                Text(step.brief)
                    .font(ChinFont.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("练完能拿下：\(step.goal) · \(step.questionCount) 题")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, ChinSpacing.sm)
    }

    private var passed: Bool { learning.isKnowledgePointPassed(step.knowledgePointID) }
    private var practiced: Bool { learning.practicedCount(for: step.knowledgePointID) > 0 }
    private var weak: Bool { learning.weakKnowledgePoints.contains(step.knowledgePointID) }

    private var statusColor: Color {
        if weak { return .orange }
        return passed ? .green : (practiced ? .blue : Color.secondary)
    }

    private var statusLabel: some View {
        Group {
            if weak {
                label("待巩固", .orange)
            } else if passed {
                label("已过关", .green)
            } else if practiced {
                label("练过", .blue)
            } else {
                label("未开始", .secondary)
            }
        }
    }

    private func label(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, ChinSpacing.sm)
            .padding(.vertical, ChinSpacing.xs)
            .background(color.opacity(0.14), in: Capsule())
    }
}

/// 单个知识点的练习页：先说清这个知识点考什么，再把配套练习直接列出来（按 基础 → 提高 → 挑战）。
struct ChinKnowledgePointPracticeView: View {
    let step: ChinPathStep

    @EnvironmentObject private var learning: ChinLearningStore
    @EnvironmentObject private var purchase: ChinPurchaseManager
    @State private var showPaywall = false

    private var module: ChinModule? { ChinModule.all.first { $0.id == step.moduleID } }

    private var allQuestions: [ChinPractice] {
        (module?.practice(grade: step.grade, knowledgePointID: step.knowledgePointID) ?? [])
            .sorted { rank($0.difficulty) < rank($1.difficulty) }
    }

    private var questions: [ChinPractice] {
        Array(allQuestions.prefix(purchase.isUnlocked ? allQuestions.count : ChinQuestionBank.freeQuestionCount))
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: ChinSpacing.sm) {
                    HStack(spacing: 6) {
                        Text("第 \(step.order) 步").font(.caption.weight(.bold)).foregroundStyle(.white)
                            .padding(.horizontal, ChinSpacing.sm).padding(.vertical, ChinSpacing.xs)
                            .background(Color.blue, in: Capsule())
                        Text(step.title).font(ChinFont.cardTitle)
                    }
                    Text("考什么：\(step.brief)").font(ChinFont.body)
                    Text("练完能拿下：\(step.goal)").font(ChinFont.body)
                    Text("\(learning.grade.title)配套 \(allQuestions.count) 道题 · 按 基础 → 提高 → 挑战 排列")
                        .font(ChinFont.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, ChinSpacing.xs)
            }

            Section("配套练习 · \(questions.count) / \(allQuestions.count) 道") {
                if allQuestions.isEmpty {
                    Text("这个知识点暂时没有练习").foregroundStyle(.secondary)
                }
                ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                    NavigationLink {
                        ChinQuestionView(question: question)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(question.prompt).font(ChinFont.body).lineLimit(2)
                                Text(difficultyTitle(question.difficulty))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }

            if !purchase.isUnlocked && allQuestions.count > ChinQuestionBank.freeQuestionCount {
                Section {
                    Button("解锁该知识点全部 \(allQuestions.count) 题") { showPaywall = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(step.title)
        .sheet(isPresented: $showPaywall) { ChinPaywallView() }
    }

    private func rank(_ d: ChinQuestionDifficulty) -> Int {
        switch d {
        case .foundation: return 0
        case .developing: return 1
        case .challenge: return 2
        }
    }

    private func difficultyTitle(_ d: ChinQuestionDifficulty) -> String {
        switch d {
        case .foundation: return "基础"
        case .developing: return "提高"
        case .challenge: return "挑战"
        }
    }
}
