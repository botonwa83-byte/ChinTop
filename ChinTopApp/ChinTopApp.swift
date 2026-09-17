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
            ChinAtlasView().tabItem { Label("能力图鉴", systemImage: "books.vertical") }.tag(2)
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
                Section("五大专题") {
                    ForEach(ChinModule.all) { module in
                        NavigationLink { ModuleView(module: module) } label: { Label(module.title, systemImage: module.icon) }
                    }
                }
            }.navigationTitle("题型场")
        }
    }
}

struct ChinAtlasView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("五项能力") {
                    ForEach(ChinCapability.all) { capability in
                        NavigationLink { ChinCapabilityDetailView(capability: capability) } label: { Label(capability.title, systemImage: capability.icon) }
                    }
                }
                Section("方法工具") { NavigationLink("方法工具箱") { ChinToolboxView() } }
            }.navigationTitle("能力图鉴")
        }
    }
}
