import SwiftUI

struct ChinPaywallView: View {
    @EnvironmentObject private var purchase: ChinPurchaseManager
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 18) {
            VStack(spacing: 8) { Image(systemName: "book.closed.fill").font(ChinFont.promoLogo).foregroundStyle(.white); Text("解锁完整版").font(ChinFont.promoQuote).foregroundStyle(.white); Text("五大专题、完整练习与逐题解析一次全开").font(.subheadline).foregroundStyle(.white.opacity(0.9)) }.frame(maxWidth: .infinity).padding(.vertical, ChinSpacing.xxl).background(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: ChinRadius.card))
            ForEach([
                ("book.pages", "五大专题完整题库"),
                ("checkmark.seal.fill", "逐题解析与错题复盘"),
                ("infinity", "一次买断，永久使用")
            ], id: \.1) { item in
                Label(item.1, systemImage: item.0).font(.headline)
            }
            ChinMilkTeaPitchCard()
            Button { Task { await purchase.purchase() } } label: { Label(purchase.isPurchasing ? "处理中…" : "立即解锁  \(purchase.product?.displayPrice ?? "—")", systemImage: "lock.open.fill").frame(maxWidth: .infinity).padding() }.buttonStyle(.borderedProminent)
            if purchase.productLoadFailed { HStack(spacing: 8) { Text("价格暂时无法加载，请检查网络").font(.caption).foregroundStyle(.orange); Button("重试") { Task { await purchase.retryLoadProduct() } }.font(.caption) } }
            Button("恢复购买") { Task { await purchase.restore() } }.frame(maxWidth: .infinity)
            if let error = purchase.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
            VStack(alignment: .leading, spacing: 8) {
                Text("购买即视为同意《用户协议》与《隐私政策》。付款通过 Apple 账户完成，换机后可用「恢复购买」找回。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ChinFamilyAdSection(current: .chin)
                ChinLegalLinksView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, ChinSpacing.xs)
        }.padding() }.navigationTitle("完整解锁").toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }.onChange(of: purchase.isUnlocked) { if $0 { dismiss() } } }
    }
}
