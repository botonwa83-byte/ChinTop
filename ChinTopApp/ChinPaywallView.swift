import SwiftUI

struct ChinPaywallView: View {
    @EnvironmentObject private var purchase: ChinPurchaseManager
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 18) {
            VStack(spacing: 8) { Image(systemName: "book.closed.fill").font(.system(size: 42)).foregroundStyle(.white); Text("解锁完整版").font(.system(size: 24, weight: .black, design: .serif)).foregroundStyle(.white); Text("五大专题、完整练习与逐题解析一次全开").font(.subheadline).foregroundStyle(.white.opacity(0.9)) }.frame(maxWidth: .infinity).padding(.vertical, 28).background(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
            ForEach([
                ("book.pages", "五大专题完整题库"),
                ("checkmark.seal.fill", "逐题解析与错题复盘"),
                ("infinity", "一次买断，永久使用")
            ], id: \.1) { item in
                Label(item.1, systemImage: item.0).font(.headline)
            }
            Button { Task { await purchase.purchase() } } label: { Label(purchase.isPurchasing ? "处理中…" : "立即解锁  \(purchase.product?.displayPrice ?? "¥22")", systemImage: "lock.open.fill").frame(maxWidth: .infinity).padding() }.buttonStyle(.borderedProminent)
            Button("恢复购买") { Task { await purchase.restore() } }.frame(maxWidth: .infinity)
            if let error = purchase.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
            VStack(alignment: .leading, spacing: 8) {
                Text("购买即视为同意《用户协议》与《隐私政策》。付款通过 Apple 账户完成，换机后可用「恢复购买」找回。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ChinLegalLinksView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }.padding() }.navigationTitle("完整解锁").toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }.onChange(of: purchase.isUnlocked) { if $0 { dismiss() } } }
    }
}
