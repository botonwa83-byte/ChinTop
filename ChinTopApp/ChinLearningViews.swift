import SwiftUI

enum ChinSidebarRoute: Hashable {
    case features
    case home
    case capabilities
    case toolbox
    case report
    case weeklyPlan
    case review
    case portfolio
    case module(String)
}

struct ChinHomeView: View {
    @EnvironmentObject private var learning: ChinLearningStore
    let onSelectModule: (ChinModule) -> Void

    private var task: ChinDailyTask { learning.todayTask }
    private var capability: ChinCapability { ChinCapability.capability(for: task.capabilityID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChinSpacing.lg) {
                header
                dailyTask
                gradePicker
                progressOverview
                HStack(spacing: ChinSpacing.md) {
                    weeklyPlanLink
                    toolboxLink
                }
                capabilityRow
                moduleRow
            }
            .padding(ChinSpacing.lg)
            .chinReadableWidth()
        }
        .background(Color.chinBackground.ignoresSafeArea())
        .navigationTitle("今日学习")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今天，完成一件能留下来的事")
                .font(.title.bold())
            Text("每次练习都留下一个答案、一个方法，或者一次更清楚的自我表达。")
                .font(ChinFont.body)
                .foregroundStyle(.secondary)
        }
    }

    private var gradePicker: some View {
        VStack(alignment: .leading, spacing: ChinSpacing.sm) {
            Text("你的学习阶段").font(ChinFont.sectionTitle)
            Picker("学习阶段", selection: Binding(
                get: { learning.grade },
                set: { learning.setGrade($0) }
            )) {
                ForEach(ChinGradeLevel.allCases) { grade in
                    Text(grade.title).tag(grade)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)
            Text(learning.grade.subtitle)
                .font(ChinFont.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chinCardSurface()
    }

    private var dailyTask: some View {
        NavigationLink {
            ChinTaskView(task: task)
        } label: {
            VStack(alignment: .leading, spacing: ChinSpacing.md) {
                HStack(spacing: ChinSpacing.sm) {
                    Label("今日能力任务", systemImage: "sun.max.fill")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: capability.icon)
                    Text("\(task.estimatedMinutes) 分钟")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.85))

                Text(task.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(task.subtitle)
                    .font(ChinFont.body)
                    .foregroundStyle(.white.opacity(0.9))
                Text(task.method)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                HStack {
                    Text(learning.snapshot.completedTaskIDs.contains(task.id) ? "今天已完成，可继续修改作品" : "先学方法，再写出自己的答案")
                        .font(ChinFont.caption)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white.opacity(0.8))
            }
            .padding(ChinSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.chinHeroStart, Color.chinHeroEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: ChinRadius.hero)
            )
            .shadow(color: Color.chinHeroEnd.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var progressOverview: some View {
        VStack(alignment: .leading, spacing: ChinSpacing.md) {
            HStack {
                Text("学习轨迹").font(ChinFont.sectionTitle)
                Spacer()
                HStack(spacing: ChinSpacing.lg) {
                    NavigationLink("成长报告") {
                        ChinLearningReportView()
                    }
                    NavigationLink("复盘") {
                        ChinReviewView()
                    }
                }
                .font(ChinFont.body)
            }
            HStack(spacing: 0) {
                ChinMetric(value: "\(learning.snapshot.currentStreak())", label: "连续学习天数", icon: "flame.fill", color: .orange)
                Divider().frame(height: 44)
                ChinMetric(value: "\(learning.snapshot.practiceCount)", label: "完成题目", icon: "checkmark.circle.fill", color: .green)
                Divider().frame(height: 44)
                ChinMetric(value: learning.snapshot.practiceCount == 0 ? "—" : "\(Int(learning.snapshot.accuracy * 100))%", label: "练习正确率", icon: "target", color: .blue)
                Divider().frame(height: 44)
                ChinMetric(value: "\(learning.snapshot.portfolio.count)", label: "作品存档", icon: "folder.fill", color: .purple)
            }
        }
        .chinCardSurface()
    }

    private var weeklyPlanLink: some View {
        NavigationLink {
            ChinWeeklyPlanView()
        } label: {
            VStack(alignment: .leading, spacing: ChinSpacing.sm) {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: ChinRadius.chip))
                Text("本周计划").font(ChinFont.cardTitle)
                Text("\(learning.weeklyPlan.completedCount)/7 天 · 每天约 8–10 分钟")
                    .font(ChinFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .chinCardSurface(padding: ChinSpacing.md)
        }
        .buttonStyle(.plain)
    }

    private var capabilityRow: some View {
        VStack(alignment: .leading, spacing: ChinSpacing.md) {
            HStack {
                Text("能力地图").font(ChinFont.sectionTitle)
                Spacer()
                NavigationLink("全部能力") {
                    ChinCapabilityMapView()
                }
                .font(ChinFont.body)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ChinSpacing.md) {
                    ForEach(ChinCapability.all) { capability in
                        NavigationLink {
                            ChinCapabilityDetailView(capability: capability)
                        } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                Image(systemName: capability.icon)
                                    .font(.title3)
                                    .foregroundStyle(color(for: capability.colorName))
                                Text(capability.title).font(ChinFont.cardTitle)
                                Text("\(learning.capabilityActivityCount(capability.id)) 次作品")
                                    .font(ChinFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 126, alignment: .leading)
                            .chinCardSurface(padding: ChinSpacing.md)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var toolboxLink: some View {
        NavigationLink {
            ChinToolboxView()
        } label: {
            VStack(alignment: .leading, spacing: ChinSpacing.sm) {
                Image(systemName: "books.vertical.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
                    .frame(width: 36, height: 36)
                    .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: ChinRadius.chip))
                Text("方法工具箱").font(ChinFont.cardTitle)
                Text("\(ChinMethodCardCatalog.all.count) 张方法卡 · 搜索后立即练习")
                    .font(ChinFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .chinCardSurface(padding: ChinSpacing.md)
        }
        .buttonStyle(.plain)
    }

    private var moduleRow: some View {
        VStack(alignment: .leading, spacing: ChinSpacing.sm) {
            Text("选择一个专题继续").font(ChinFont.sectionTitle)
            VStack(spacing: 0) {
                ForEach(Array(ChinModule.all.enumerated()), id: \.element.id) { index, module in
                    Button { onSelectModule(module) } label: {
                        HStack(spacing: ChinSpacing.md) {
                            Image(systemName: module.icon)
                                .font(.title3)
                                .frame(width: 34, height: 34)
                                .foregroundStyle(module.color)
                                .background(module.color.opacity(0.14), in: RoundedRectangle(cornerRadius: ChinRadius.chip))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(module.title).font(ChinFont.cardTitle)
                                Text(module.subtitle).font(ChinFont.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    if index < ChinModule.all.count - 1 {
                        Divider().padding(.leading, 46)
                    }
                }
            }
            .chinCardSurface(padding: ChinSpacing.md)
        }
    }

    private func color(for name: String) -> Color {
        switch name {
        case "orange": return .orange
        case "green": return .green
        case "pink": return .pink
        case "purple": return .purple
        default: return .blue
        }
    }
}

struct ChinMetric: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(ChinFont.bigStat())
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ChinCapabilityMapView: View {
    @EnvironmentObject private var learning: ChinLearningStore

    var body: some View {
        List {
            Section {
                Text("能力不是一个分数，而是一组可以反复使用的方法。完成任务、写下作品、复盘错题，都会留下可回看的证据。")
                    .foregroundStyle(.secondary)
            }
            ForEach(ChinCapability.all) { capability in
                NavigationLink {
                    ChinCapabilityDetailView(capability: capability)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: capability.icon)
                            .font(.title3)
                            .foregroundStyle(color(for: capability.colorName))
                            .frame(width: 34)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(capability.title).font(.headline)
                            Text(capability.subtitle).font(.subheadline).foregroundStyle(.secondary)
                            Text("\(learning.capabilityActivityCount(capability.id)) 次作品 · \(taskCount(for: capability.id)) 个任务")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("能力地图")
    }

    private func taskCount(for capabilityID: String) -> Int {
        ChinDailyTaskCatalog.all.filter { $0.capabilityID == capabilityID }.count
    }

    private func color(for name: String) -> Color {
        switch name {
        case "orange": return .orange
        case "green": return .green
        case "pink": return .pink
        case "purple": return .purple
        default: return .blue
        }
    }
}

struct ChinCapabilityDetailView: View {
    let capability: ChinCapability
    @EnvironmentObject private var learning: ChinLearningStore

    private var tasks: [ChinDailyTask] {
        ChinDailyTaskCatalog.all.filter { $0.capabilityID == capability.id }
    }

    var body: some View {
        List {
            Section {
                Label(capability.subtitle, systemImage: capability.icon)
                Text(capability.detail).foregroundStyle(.secondary)
                Text("已留下 \(learning.capabilityActivityCount(capability.id)) 份作品")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            Section("练习路径") {
                ForEach(tasks) { task in
                    NavigationLink {
                        ChinTaskView(task: task)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title).font(.headline)
                            Text(task.method).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section {
                NavigationLink {
                    ChinToolboxView(initialCapabilityID: capability.id)
                } label: {
                    Label("查看这个能力的方法卡", systemImage: "books.vertical.fill")
                }
            }
        }
        .navigationTitle(capability.title)
    }
}

struct ChinToolboxView: View {
    @State private var query = ""
    @State private var selectedCapabilityID: String

    init(initialCapabilityID: String? = nil) {
        _selectedCapabilityID = State(initialValue: initialCapabilityID ?? "all")
    }

    private var cards: [ChinMethodCard] {
        ChinMethodCardCatalog.search(
            query: query,
            capabilityID: selectedCapabilityID == "all" ? nil : selectedCapabilityID
        )
    }

    var body: some View {
        List {
            Section {
                Text("方法卡不是背诵清单，而是遇到新题时可以调用的步骤。先选一张，再用关联任务练一次。")
                    .foregroundStyle(.secondary)
            }
            if cards.isEmpty {
                ChinEmptyState(
                    title: "没有匹配的方法卡",
                    systemImage: "magnifyingglass",
                    message: "换一个关键词，或把能力筛选切换为全部。"
                )
            } else {
                Section("\(cards.count) 张方法卡") {
                    ForEach(cards) { card in
                        NavigationLink {
                            ChinMethodCardDetailView(card: card)
                        } label: {
                            ChinMethodCardRow(card: card)
                        }
                    }
                }
            }
        }
        .navigationTitle("方法工具箱")
        .searchable(text: $query, prompt: "搜索证据、语境、表达……")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button {
                        selectedCapabilityID = "all"
                    } label: {
                        Label("全部能力", systemImage: selectedCapabilityID == "all" ? "checkmark" : "")
                    }
                    ForEach(ChinCapability.all) { capability in
                        Button {
                            selectedCapabilityID = capability.id
                        } label: {
                            Label(
                                capability.title,
                                systemImage: selectedCapabilityID == capability.id ? "checkmark" : ""
                            )
                        }
                    }
                } label: {
                    Label("筛选", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

struct ChinMethodCardRow: View {
    let card: ChinMethodCard

    private var capability: ChinCapability {
        ChinCapability.capability(for: card.capabilityID)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: capability.icon)
                .font(.title3)
                .foregroundStyle(color(for: capability.colorName))
                .frame(width: 36, height: 36)
                .background(color(for: capability.colorName).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(card.title).font(.headline)
                Text(card.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(capability.title)
                    .font(.caption)
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 4)
    }

    private func color(for name: String) -> Color {
        switch name {
        case "orange": return .orange
        case "green": return .green
        case "pink": return .pink
        case "purple": return .purple
        default: return .blue
        }
    }
}

struct ChinMethodCardDetailView: View {
    let card: ChinMethodCard

    private var capability: ChinCapability {
        ChinCapability.capability(for: card.capabilityID)
    }

    private var relatedTask: ChinDailyTask? {
        guard let taskID = card.taskID else { return nil }
        return ChinDailyTaskCatalog.all.first(where: { $0.id == taskID })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(capability.title, systemImage: capability.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tint)
                    Text(card.title)
                        .font(.largeTitle.bold())
                    Text(card.summary)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("使用步骤").font(.headline)
                    ForEach(Array(card.steps.enumerated()), id: \.offset) { index, step in
                        Label(step, systemImage: "\(index + 1).circle.fill")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("示例").font(.headline)
                    Text(card.example)
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("自我提醒").font(.headline)
                    Label(card.practicePrompt, systemImage: "checkmark.bubble")
                        .foregroundStyle(.secondary)
                }

                if let relatedTask {
                    NavigationLink {
                        ChinTaskView(task: relatedTask)
                    } label: {
                        Label("立即练习这张方法卡", systemImage: "arrow.right.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(maxWidth: 760, alignment: .leading)
        }
        .navigationTitle("方法卡")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChinLearningReportView: View {
    @EnvironmentObject private var learning: ChinLearningStore

    private var report: ChinLearningReport {
        learning.learningReport
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                reportHeader
                summary
                focusCard
                capabilityEvidence
                reportNote
            }
            .padding()
            .frame(maxWidth: 900, alignment: .leading)
        }
        .navigationTitle("成长报告")
    }

    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("你的学习证据")
                .font(.largeTitle.bold())
            Text("报告只统计你在本设备上完成的题目、任务和作品，不用猜测，也不把一次表现定义成能力。")
                .foregroundStyle(.secondary)
            Text(report.headline)
                .font(.headline)
                .foregroundStyle(.tint)
                .padding(.top, 4)
        }
    }

    private var summary: some View {
        HStack(spacing: 0) {
            ChinMetric(value: "\(report.activeDayCount)", label: "有记录的天数", icon: "calendar.badge.checkmark", color: .blue)
            Divider().frame(height: 42)
            ChinMetric(value: "\(report.portfolioCount)", label: "作品", icon: "folder.fill", color: .purple)
            Divider().frame(height: 42)
            ChinMetric(value: "\(report.unresolvedMistakeCount)", label: "待复盘", icon: "arrow.triangle.2.circlepath", color: .orange)
            Divider().frame(height: 42)
            ChinMetric(value: report.accuracyPercent.map { "\($0)%" } ?? "—", label: "练习正确率", icon: "target", color: .green)
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var focusCard: some View {
        if let focus = report.focusCapability {
            let evidence = report.capabilities.first(where: { $0.capabilityID == focus.id })
            VStack(alignment: .leading, spacing: 9) {
                Label("下一步建议", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("把注意力放在「\(focus.title)」")
                    .font(.title3.bold())
                if let evidence {
                    Text(evidence.nextAction)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var capabilityEvidence: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("五项能力的当前证据").font(.headline)
            ForEach(report.capabilities) { evidence in
                ChinCapabilityEvidenceRow(evidence: evidence)
            }
        }
    }

    private var reportNote: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("怎样让报告变得更有用", systemImage: "lightbulb")
                .font(.headline)
            Text("每完成一次任务，写下自己的答案和下一步；每道错题看清正确依据。记录越完整，下一步建议越具体。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct ChinCapabilityEvidenceRow: View {
    let evidence: ChinCapabilityEvidence

    private var capability: ChinCapability {
        ChinCapability.capability(for: evidence.capabilityID)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: capability.icon)
                .font(.title3)
                .foregroundStyle(color(for: capability.colorName))
                .frame(width: 36, height: 36)
                .background(color(for: capability.colorName).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(evidence.title).font(.headline)
                    Spacer()
                    Text(evidence.status.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                }
                Text("\(evidence.portfolioCount) 份作品 · \(evidence.taskCount) 个任务")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(evidence.nextAction)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var statusColor: Color {
        switch evidence.status {
        case .notStarted: return .secondary
        case .building: return .green
        case .needsReview: return .orange
        }
    }

    private func color(for name: String) -> Color {
        switch name {
        case "orange": return .orange
        case "green": return .green
        case "pink": return .pink
        case "purple": return .purple
        default: return .blue
        }
    }
}

struct ChinWeeklyPlanView: View {
    @EnvironmentObject private var learning: ChinLearningStore

    private var plan: ChinWeeklyPlan {
        learning.weeklyPlan
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("本周完成 \(plan.completedCount)/7 天").font(.headline)
                        Spacer()
                        Text("\(Int(plan.progress * 100))%")
                            .font(.headline)
                            .foregroundStyle(.tint)
                    }
                    ProgressView(value: plan.progress)
                    Text("每天一个短任务，练习后留下作品。漏掉一天也不用补做，继续完成今天即可。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 5)
            }
            Section("七天路径") {
                ForEach(plan.days) { day in
                    NavigationLink {
                        ChinTaskView(task: task(for: day))
                    } label: {
                        HStack(spacing: 12) {
                            VStack(spacing: 3) {
                                Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.caption.weight(.semibold))
                                Text(day.date.formatted(.dateTime.day()))
                                    .font(.title3.bold())
                            }
                            .frame(width: 46)
                            .foregroundStyle(isToday(day.date) ? Color.accentColor : Color.primary)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(day.title).font(.headline)
                                    if isToday(day.date) {
                                        Text("今天")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.tint)
                                    }
                                }
                                Text(day.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(day.estimatedMinutes) 分钟")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Image(systemName: day.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(day.isCompleted ? .green : .secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("本周计划")
    }

    private func task(for day: ChinPlanDay) -> ChinDailyTask {
        ChinDailyTaskCatalog.task(for: day.date, grade: learning.grade)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct ChinTaskView: View {
    let task: ChinDailyTask
    @EnvironmentObject private var learning: ChinLearningStore
    @Environment(\.dismiss) private var dismiss
    @State private var response = ""
    @State private var reflection = ""
    @State private var hasEvidence = false
    @State private var isClear = false
    @State private var isComplete = false
    @State private var showExample = false

    private var canSave: Bool {
        !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                methodCard
                challengeCard
                responseEditor
                reflectionEditor
                selfReview
                saveButton
            }
            .padding()
            .frame(maxWidth: 760, alignment: .leading)
        }
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let existing = learning.snapshot.portfolio.first(where: { $0.taskID == task.id }) {
                response = existing.response
                reflection = existing.reflection
                hasEvidence = existing.checklist["有文本证据"] ?? false
                isClear = existing.checklist["观点说清楚"] ?? false
                isComplete = existing.checklist["语言完整"] ?? false
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(task.subtitle).font(.subheadline.weight(.semibold)).foregroundStyle(.tint)
            Text(task.title).font(.largeTitle.bold())
            Text("\(task.estimatedMinutes) 分钟 · 写下自己的答案，系统会保存到作品库")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var methodCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("先学方法", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(task.method).font(.headline)
            ForEach(Array(task.steps.enumerated()), id: \.offset) { index, step in
                Label(step, systemImage: "\(index + 1).circle.fill")
                    .font(.subheadline)
            }
            if let methodCard = ChinMethodCardCatalog.card(forTaskID: task.id) {
                NavigationLink {
                    ChinMethodCardDetailView(card: methodCard)
                } label: {
                    Label("查看完整方法卡", systemImage: "arrow.up.right")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private var challengeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("挑战").font(.headline)
            Text(task.challenge)
                .font(.body)
                .textSelection(.enabled)
        }
    }

    private var responseEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.prompt).font(.headline)
            TextEditor(text: $response)
                .frame(minHeight: 150)
                .padding(8)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.22))
                }
            Text("先写自己的版本，再对照示例修改。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var reflectionEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("我的下一步").font(.headline)
            TextField("例如：下次先圈出动作，再写人物品质", text: $reflection, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.22))
                }
        }
    }

    private var selfReview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("提交前自评").font(.headline)
                Spacer()
                Button(showExample ? "收起示例" : "查看示例") {
                    withAnimation { showExample.toggle() }
                }
                .font(.subheadline)
            }
            Toggle("我找到了文本或题目中的证据", isOn: $hasEvidence)
            Toggle("我把观点说清楚了", isOn: $isClear)
            Toggle("我的句子完整、读起来通顺", isOn: $isComplete)
            if showExample {
                VStack(alignment: .leading, spacing: 6) {
                    Text("参考示例").font(.subheadline.weight(.semibold))
                    Text(task.example).font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var saveButton: some View {
        Button {
            learning.savePortfolio(
                task: task,
                response: response.trimmingCharacters(in: .whitespacesAndNewlines),
                reflection: reflection.trimmingCharacters(in: .whitespacesAndNewlines),
                checklist: [
                    "有文本证据": hasEvidence,
                    "观点说清楚": isClear,
                    "语言完整": isComplete
                ]
            )
            dismiss()
        } label: {
            Label("保存到我的作品", systemImage: "tray.and.arrow.down.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canSave)
    }
}

struct ChinReviewView: View {
    @EnvironmentObject private var learning: ChinLearningStore

    var body: some View {
        List {
            if learning.snapshot.mistakes.isEmpty {
                ChinEmptyState(
                    title: "还没有错题",
                    systemImage: "checkmark.seal",
                    message: "在专题练习里提交答案，答错的题目会自动进入这里。"
                )
            } else {
                Section("待复盘 · \(learning.snapshot.unresolvedMistakes.count)") {
                    ForEach(learning.snapshot.unresolvedMistakes) { mistake in
                        NavigationLink {
                            ChinMistakeReviewView(mistake: mistake)
                        } label: {
                            mistakeRow(mistake)
                        }
                    }
                }
                if learning.snapshot.mistakes.contains(where: { $0.isResolved }) {
                    Section("已经掌握") {
                        ForEach(learning.snapshot.mistakes.filter(\.isResolved)) { mistake in
                            mistakeRow(mistake)
                        }
                    }
                }
            }
        }
        .navigationTitle("错题复盘")
    }

    private func mistakeRow(_ mistake: ChinMistakeRecord) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(mistake.skill).font(.headline)
            Text(mistake.prompt).font(.subheadline).lineLimit(2)
            HStack {
                Text(mistake.isResolved ? "已复盘 \(mistake.reviewCount) 次" : "需要再看一次")
                Spacer()
                Text(mistake.moduleID).textCase(.uppercase)
            }
            .font(.caption)
            .foregroundStyle(mistake.isResolved ? .green : .orange)
        }
        .padding(.vertical, 4)
    }
}

struct ChinMistakeReviewView: View {
    let mistake: ChinMistakeRecord
    @EnvironmentObject private var learning: ChinLearningStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label(mistake.skill, systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                Text(mistake.prompt).font(.title2.bold())
                answerBlock(title: "你当时的答案", text: mistake.selectedAnswer, tint: .red)
                answerBlock(title: "正确答案", text: mistake.correctAnswer, tint: .green)
                VStack(alignment: .leading, spacing: 8) {
                    Text("为什么").font(.headline)
                    Text(mistake.explanation)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                Button {
                    learning.resolveMistake(mistake.id)
                    dismiss()
                } label: {
                    Label(mistake.isResolved ? "再次记录复盘" : "我已记住这个方法", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: 700, alignment: .leading)
        }
        .navigationTitle("复盘卡")
    }

    private func answerBlock(title: String, text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(tint)
            Text(text).font(.body)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct ChinPortfolioView: View {
    @EnvironmentObject private var learning: ChinLearningStore

    var body: some View {
        List {
            if learning.snapshot.portfolio.isEmpty {
                ChinEmptyState(
                    title: "作品库还是空的",
                    systemImage: "folder",
                    message: "完成今日能力任务，写下你的答案，它会出现在这里。"
                )
            } else {
                Section("我的作品 · \(learning.snapshot.portfolio.count)") {
                    ForEach(learning.snapshot.portfolio) { entry in
                        NavigationLink {
                            ChinPortfolioDetailView(entry: entry)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(entry.title).font(.headline)
                                    Spacer()
                                    Text("\(Int(entry.checklistProgress * 100))% 自评")
                                        .font(.caption)
                                        .foregroundStyle(.tint)
                                }
                                Text(entry.response)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("我的作品")
    }
}

struct ChinPortfolioDetailView: View {
    let entry: ChinPortfolioEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(entry.title).font(.largeTitle.bold())
                Text(entry.prompt).font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    Text("我的答案").font(.headline)
                    Text(entry.response).textSelection(.enabled)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("我的下一步").font(.headline)
                    Text(entry.reflection.isEmpty ? "还没有写下下一步。" : entry.reflection)
                        .foregroundStyle(entry.reflection.isEmpty ? .secondary : .primary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("提交前自评").font(.headline)
                    ForEach(entry.checklist.keys.sorted(), id: \.self) { key in
                        Label(key, systemImage: entry.checklist[key] == true ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(entry.checklist[key] == true ? .green : .secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 700, alignment: .leading)
        }
        .navigationTitle("作品详情")
    }
}

struct ChinEmptyState: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .foregroundStyle(.tint)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .listRowBackground(Color.clear)
    }
}
