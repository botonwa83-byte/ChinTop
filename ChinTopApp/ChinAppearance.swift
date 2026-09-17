import SwiftUI

enum ChinAppearancePreference: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self { case .system: return "跟随系统"; case .light: return "浅色"; case .dark: return "深色" }
    }
    var icon: String {
        switch self { case .system: return "circle.lefthalf.filled"; case .light: return "sun.max.fill"; case .dark: return "moon.fill" }
    }
    var colorScheme: ColorScheme? { self == .light ? .light : (self == .dark ? .dark : nil) }
}

@MainActor final class ChinAppearanceManager: ObservableObject {
    static let shared = ChinAppearanceManager()
    @Published var preference: ChinAppearancePreference {
        didSet { UserDefaults.standard.set(preference.rawValue, forKey: "chintop.appearance") }
    }
    var colorScheme: ColorScheme? { preference.colorScheme }
    private init() {
        preference = ChinAppearancePreference(rawValue: UserDefaults.standard.string(forKey: "chintop.appearance") ?? "") ?? .system
    }
}

struct ChinFeatureView: View {
    @EnvironmentObject private var purchase: ChinPurchaseManager
    @ObservedObject private var appearance = ChinAppearanceManager.shared
    @State private var showPaywall = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !purchase.isUnlocked { unlockCard }
                    featureSection("学习能力", "brain.head.profile", .blue) {
                        featureLink("point.3.connected.trianglepath.dotted", "能力地图", "五项能力，从证据到表达逐步练习") { ChinCapabilityMapView() }
                        featureLink("books.vertical.fill", "方法工具箱", "12 张方法卡，学会后马上迁移") { ChinToolboxView() }
                    }
                    featureSection("学习记录", "chart.bar.doc.horizontal", .green) {
                        featureLink("chart.bar.doc.horizontal", "成长报告", "只根据真实学习记录给出下一步") { ChinLearningReportView() }
                        featureLink("calendar", "本周计划", "每天一个短任务，形成稳定节奏") { ChinWeeklyPlanView() }
                        featureLink("arrow.triangle.2.circlepath", "错题复盘", "把错因、依据和下一步记录下来") { ChinReviewView() }
                        featureLink("folder.fill", "我的作品", "保存答案与自评，看到自己的变化") { ChinPortfolioView() }
                    }
                    featureSection("五大专题", "book.pages", .orange) {
                        ForEach(ChinModule.all) { module in
                            featureLink(module.icon, module.title, module.subtitle) { ModuleView(module: module) }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Label("外观", systemImage: "paintbrush").font(.headline).foregroundStyle(.green)
                        Picker("显示模式", selection: $appearance.preference) {
                            ForEach(ChinAppearancePreference.allCases) { pref in Label(pref.label, systemImage: pref.icon).tag(pref) }
                        }.pickerStyle(.navigationLink)
                    }.padding().background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: ChinRadius.inner))
                    aboutSection
                }.padding().frame(maxWidth: 760, alignment: .leading)
            }.navigationTitle("功能").sheet(isPresented: $showPaywall) { ChinPaywallView() }
        }
    }
    private var unlockCard: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill").foregroundStyle(.white).frame(width: 44, height: 44).background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: ChinRadius.pill))
                VStack(alignment: .leading, spacing: 3) { Text("解锁完整版").font(.headline).foregroundStyle(.white); Text("五大专题完整题库 · 逐题解析 · 一次买断").font(.caption).foregroundStyle(.white.opacity(0.9)) }
                Spacer(); Text(purchase.product?.displayPrice ?? "¥22").font(.headline).foregroundStyle(.white)
            }.padding().background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: ChinRadius.panel))
        }.buttonStyle(.plain)
    }
    /// 「关于」区块：与 MathTop「我的 · 关于」保持同一套版式
    /// —— 区块标题 + 内容统计行 + 分隔线 + 协议链接 + 版本署名。
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: ChinSpacing.md) {
            Label("关于", systemImage: "info.circle").font(.headline).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: ChinSpacing.sm) {
                aboutRow("知识点总数", "\(ChinQuestionBank.knowledgePointCatalog.count) 个")
                aboutRow("配套练习总数", "\(ChinQuestionBank.all.count) 道")
                aboutRow("每个知识点配套题量", "不少于 \(ChinQuestionBank.targetCount(importance: .extension)) 道")
                aboutRow("学习活动库", "\(ChinDailyTaskCatalog.all.count) 个每日任务")
            }
            Divider()
            ChinLegalLinksView()
            Text("ChinTop · 语文登顶  v1.0.0\n© 2026 Top King. All rights reserved.")
                .font(ChinFont.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chinCardSurface()
    }

    private func aboutRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(ChinFont.body).foregroundStyle(.secondary)
            Spacer(minLength: ChinSpacing.sm)
            Text(value).font(ChinFont.body).bold().foregroundStyle(.primary)
        }
    }

    private func featureSection<Content: View>(_ title: String, _ icon: String, _ color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) { Label(title, systemImage: icon).font(.headline).foregroundStyle(color); VStack(spacing: 10) { content() } }
    }
    private func featureLink<Destination: View>(_ icon: String, _ title: String, _ subtitle: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink { destination() } label: { HStack(spacing: 12) { Image(systemName: icon).font(.title3).foregroundStyle(.tint).frame(width: 38, height: 38).background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: ChinRadius.chip)); VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline); Text(subtitle).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary) }.padding(ChinSpacing.md).background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: ChinRadius.pill)) }.buttonStyle(.plain)
    }
}
