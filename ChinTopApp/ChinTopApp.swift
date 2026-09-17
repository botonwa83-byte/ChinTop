import SwiftUI

@main
struct ChinTopApp: App {
    @StateObject private var purchase = ChinPurchaseManager.shared
    @StateObject private var learning = ChinLearningStore()
    @StateObject private var appearance = ChinAppearanceManager.shared

    var body: some Scene {
        WindowGroup {
            ChinRootView()
                .environmentObject(purchase)
                .environmentObject(learning)
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}

struct ChinRootView: View {
    var body: some View { ContentView() }
}

struct ContentView: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            ChinMainlineView().tabItem { Label("学习主线", systemImage: "map") }.tag(0)
            ChinPracticeHubView().tabItem { Label("题型场", systemImage: "square.and.pencil") }.tag(1)
            ChinPathTabView().tabItem { Label("学习路径", systemImage: "list.number") }.tag(2)
            ChinFeatureView().tabItem { Label("功能宝藏", systemImage: "sparkles") }.tag(3)
        }
        .tint(.pink)
    }
}

struct ChinMainlineView: View {
    @State private var selectedModule: ChinModule?
    var body: some View {
        NavigationStack {
            ChinHomeView { selectedModule = $0 }
                .navigationTitle("学习主线")
                .sheet(item: $selectedModule) { ModuleView(module: $0) }
        }
    }
}

struct ChinPracticeHubView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("五大专题 · 按文体找题；想按顺序学，去「学习路径」") {
                    ForEach(ChinModule.all) { module in
                        NavigationLink { ModuleView(module: module) } label: { Label(module.title, systemImage: module.icon) }
                    }
                }
            }.navigationTitle("题型场")
        }
    }
}

/// 「学习路径」页：按学段列出有序知识点，学生照着序号往下练即可。
/// 原「能力图鉴」以抽象能力与方法卡为主，学生不知道从何学起，已改为路径主导；
/// 能力地图与方法工具箱入口保留在「功能宝藏」页。
struct ChinPathTabView: View {
    var body: some View {
        NavigationStack {
            ChinLearningPathView()
        }
    }
}
