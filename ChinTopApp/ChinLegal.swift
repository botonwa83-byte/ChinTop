import SwiftUI

// MARK: - 上线合规入口（GitHub Pages 托管，付费墙与设置共用同一组链接）

enum ChinLegal {
    static let site = URL(string: "https://botonwa83-byte.github.io/ChinTop/")!
    static let termsURL = URL(string: "https://botonwa83-byte.github.io/ChinTop/terms.html")!
    static let privacyURL = URL(string: "https://botonwa83-byte.github.io/ChinTop/privacy.html")!
    static let supportURL = URL(string: "https://botonwa83-byte.github.io/ChinTop/support.html")!
}

/// 协议与隐私入口：付费墙底部 + 功能页「关于与协议」共用。
struct ChinLegalLinksView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Link("用户协议", destination: ChinLegal.termsURL)
            Link("隐私政策", destination: ChinLegal.privacyURL)
            Link("技术支持", destination: ChinLegal.supportURL)
        }
        .font(.footnote)
    }
}
