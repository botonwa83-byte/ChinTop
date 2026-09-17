import SwiftUI

// MARK: - Top King 同门软件推荐位（首页广告页与解锁页共用）
//
// 广告位目的：让用户知道这是一整套同厂出品的学习工具——
// 同一套「会拆题、记错因、给下一步」的引擎，攻克一科，另外两科直接上手。
// 链接先指向各自官网（App Store 上架后把 url 换成 itms-apps://apps.apple.com/cn/app/idXXXX 即可）。

enum ChinFamilyApp: String, CaseIterable, Identifiable {
    case chin
    case math
    case eng

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chin: return "语文登顶 ChinTop"
        case .math: return "数学登顶 MathTop"
        case .eng: return "英语登顶 EngTop"
        }
    }

    var pitch: String {
        switch self {
        case .chin: return "证据表达力：阅读、文言、诗词、作文，写得出采分点"
        case .math: return "建模推理力：把应用题拆成步骤，压轴题也敢下手"
        case .eng: return "考点导航力：语法、完形、读后续写，先补最容易丢分的那块"
        }
    }

    var icon: String {
        switch self {
        case .chin: return "book.closed.fill"
        case .math: return "function"
        case .eng: return "character.book.closed.fill"
        }
    }

    var tint: Color {
        switch self {
        case .chin: return .pink
        case .math: return .orange
        case .eng: return .purple
        }
    }

    var url: URL {
        switch self {
        case .chin: return ChinLegal.site
        case .math: return URL(string: "https://botonwa83-byte.github.io/MathTop/")!
        case .eng: return URL(string: "https://botonwa83-byte.github.io/EngTop/")!
        }
    }
}

/// 同门三件套推荐位。`onDark` 用于首页广告页这类深色底场景。
struct ChinFamilyAdSection: View {
    var current: ChinFamilyApp = .chin
    var onDark: Bool = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: ChinSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(ChinFont.caption)
                    .foregroundStyle(.orange)
                Text("Top King 出品 · 同门三件套")
                    .font(ChinFont.caption)
                    .foregroundStyle(secondaryText)
            }
            ForEach(ChinFamilyApp.allCases) { app in
                ChinFamilyAdRow(app: app, isCurrent: app == current, onDark: onDark) { openURL(app.url) }
            }
            Text("同一套学习引擎：会拆题、记错因、给下一步。攻克一科，另外两科直接上手。")
                .font(ChinFont.caption)
                .foregroundStyle(tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ChinSpacing.lg)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: ChinRadius.card))
    }

    private var cardBackground: Color { onDark ? Color.white.opacity(0.08) : Color.chinCard }
    private var secondaryText: Color { onDark ? Color.white.opacity(0.7) : Color.secondary }
    private var tertiaryText: Color { onDark ? Color.white.opacity(0.5) : Color.secondary.opacity(0.8) }
}

private struct ChinFamilyAdRow: View {
    let app: ChinFamilyApp
    let isCurrent: Bool
    let onDark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ChinSpacing.md) {
                Image(systemName: app.icon)
                    .font(ChinFont.body)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(app.tint, in: RoundedRectangle(cornerRadius: ChinRadius.inner))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(app.title)
                            .font(ChinFont.cardTitle)
                            .foregroundStyle(onDark ? .white : .primary)
                        if isCurrent {
                            Text("使用中")
                                .font(ChinFont.caption)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(onDark ? 0.22 : 0.14), in: Capsule())
                        }
                    }
                    Text(app.pitch)
                        .font(ChinFont.caption)
                        .foregroundStyle(onDark ? Color.white.opacity(0.65) : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(ChinFont.caption)
                    .foregroundStyle(onDark ? Color.white.opacity(0.45) : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("了解 \(app.title)")
    }
}

// MARK: - 一杯奶茶价说服卡

/// 价格锚点：把一次买断翻译成「一杯奶茶」，并给出「先逛逛再决定」的退路，降低决策压力。
struct ChinMilkTeaPitchCard: View {
    var onDark: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: ChinSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(ChinFont.caption)
                    .foregroundStyle(.orange)
                Text("一杯奶茶 vs 一次解锁")
                    .font(ChinFont.caption)
                    .foregroundStyle(secondaryText)
            }
            Text("一杯奶茶的钱，买到「有话可说、有据可依」")
                .font(ChinFont.sectionTitle)
                .foregroundStyle(onDark ? .white : .primary)
                .fixedSize(horizontal: false, vertical: true)
            Text("阅读、文言、诗词、作文、综合五大专题一次全开。奶茶喝完就忘了，采分点却会一直替你拿分。")
                .font(ChinFont.body)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: ChinSpacing.sm) {
                pitchRow("奶茶：一口的快乐，两个小时就忘", tint: .secondary)
                pitchRow("解锁：不再「读懂了写不出」，证据 → 采分点 → 表达三步走", tint: .green)
                pitchRow("今天少喝一杯奶茶，作文里多一份稳稳拿到的采分点", tint: .pink)
            }
            Text("免费内容永久保留：先逛一圈再决定，想通了回来，价格不变。")
                .font(ChinFont.caption)
                .foregroundStyle(tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ChinSpacing.lg)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: ChinRadius.card))
    }

    private func pitchRow(_ text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: ChinSpacing.sm) {
            Circle().fill(tint).frame(width: 6, height: 6).padding(.top, 6)
            Text(text)
                .font(ChinFont.body)
                .foregroundStyle(onDark ? Color.white.opacity(0.85) : .primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var cardBackground: Color { onDark ? Color.white.opacity(0.08) : Color.chinCard }
    private var secondaryText: Color { onDark ? Color.white.opacity(0.7) : Color.secondary }
    private var tertiaryText: Color { onDark ? Color.white.opacity(0.5) : Color.secondary.opacity(0.8) }
}

// MARK: - 「要不要现在解锁」询问卡

/// 给一个明确的「是 / 否」：想买就买，不想买就先逛——免费内容不缩水，随时可以回来。
struct ChinUnlockAskCard: View {
    let price: String
    var onDark: Bool = false
    let onUnlock: () -> Void
    let onBrowse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ChinSpacing.md) {
            Text("要不要用一杯奶茶的价格，解锁整个 ChinTop？")
                .font(ChinFont.sectionTitle)
                .foregroundStyle(onDark ? .white : .primary)
                .fixedSize(horizontal: false, vertical: true)
            Text("解锁后：五大专题完整题库 + 逐题解析 + 错题复盘，一次买断，永久使用。")
                .font(ChinFont.body)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onUnlock) {
                Label("好，一杯奶茶换一整年底气  \(price)", systemImage: "lock.open.fill")
                    .font(ChinFont.cardTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ChinSpacing.md)
                    .background(.pink, in: RoundedRectangle(cornerRadius: ChinRadius.panel))
            }
            .buttonStyle(.plain)
            Button(action: onBrowse) {
                Text("先逛逛，等会儿再决定")
                    .font(ChinFont.body)
                    .foregroundStyle(secondaryText)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            Text("先浏览也行：免费内容不缩水，想好了随时回来解锁。")
                .font(ChinFont.caption)
                .foregroundStyle(tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ChinSpacing.lg)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: ChinRadius.card))
    }

    private var cardBackground: Color { onDark ? Color.white.opacity(0.08) : Color.chinCard }
    private var secondaryText: Color { onDark ? Color.white.opacity(0.7) : Color.secondary }
    private var tertiaryText: Color { onDark ? Color.white.opacity(0.5) : Color.secondary.opacity(0.8) }
}
