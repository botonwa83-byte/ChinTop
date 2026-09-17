import SwiftUI

// MARK: - ChinTop 设计系统：统一间距 / 圆角 / 字阶 / 卡片样式（参照 EngTop DesignSystem）

enum ChinSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
}

enum ChinRadius {
    static let chip: CGFloat = 8
    static let inner: CGFloat = 12
    static let card: CGFloat = 16
    static let hero: CGFloat = 20
}

enum ChinFont {
    static let sectionTitle = Font.headline
    static let cardTitle = Font.subheadline.weight(.bold)
    static let body = Font.subheadline
    static let caption = Font.caption
    static func bigStat(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

extension Color {
    /// 页面底色：浅灰（深色模式自动变深）
    static var chinBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray6)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }
    /// 卡片底色（深色模式自动适配）
    static var chinCard: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
    /// 主题渐变（任务英雄卡）
    static let chinHeroStart = Color(red: 0.30, green: 0.42, blue: 0.93)
    static let chinHeroEnd = Color(red: 0.58, green: 0.35, blue: 0.88)
}

extension View {
    func chinCardShadow() -> some View {
        shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    /// 白底卡片：padding + 白底 + 圆角 + 轻投影
    func chinCardSurface(padding: CGFloat = ChinSpacing.lg) -> some View {
        self
            .padding(padding)
            .background(Color.chinCard)
            .cornerRadius(ChinRadius.card)
            .chinCardShadow()
    }

    /// 大屏可读宽度：iPad/Catalyst 下限制最大宽度并居中，iPhone 无影响
    func chinReadableWidth(_ maxWidth: CGFloat = 720) -> some View {
        modifier(ChinReadableWidthModifier(maxWidth: maxWidth))
    }
}

private struct ChinReadableWidthModifier: ViewModifier {
    let maxWidth: CGFloat
    @Environment(\.horizontalSizeClass) private var sizeClass
    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content.frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}
