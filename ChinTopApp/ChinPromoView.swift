import SwiftUI

struct ChinPromoView: View {
    let onEnter: () -> Void
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.12, green: 0.08, blue: 0.18), Color(red: 0.28, green: 0.12, blue: 0.22)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Image(systemName: "book.closed.fill").font(ChinFont.promoGlyph).foregroundStyle(.pink).padding(ChinSpacing.page).background(.pink.opacity(0.18), in: Circle()).padding(.top, 42)
                    Text("CHIN TOP").font(ChinFont.promoBrand).tracking(3).foregroundStyle(.white)
                    Text("语 文 登 顶 · 得 分 导 航").font(.subheadline).tracking(2).foregroundStyle(.white.opacity(0.65))
                    Text("赋予学生一项能力：证据表达力").font(.headline).multilineTextAlignment(.center).foregroundStyle(.pink).padding(.top, ChinSpacing.md)
                    Text("从文本中找到证据，组织采分点，再用准确、有层次的语言表达出来，让思考变成看得见的进步。").font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.65))
                    ForEach([("sun.max.fill", "每日能力任务：先学方法，再写出自己的答案"), ("calendar", "本周计划：每天一个短任务，形成稳定节奏"), ("book.pages", "五大专题：阅读、文言、诗词、作文、综合学习"), ("chart.bar.doc.horizontal", "成长报告：只根据真实学习记录给出下一步"), ("arrow.triangle.2.circlepath", "错题复盘：把错因、依据和下一步记录下来"), ("folder.fill", "作品库：保存答案与自评，看到自己的变化")], id: \.1) { item in
                        Label(item.1, systemImage: item.0).frame(maxWidth: .infinity, alignment: .leading).padding(ChinSpacing.field).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: ChinRadius.panel)).foregroundStyle(.white)
                    }
                    HStack { stat("\(ChinModule.all.count)", "语文专题"); Divider().frame(height: 28); stat("\(ChinDailyTaskCatalog.all.count)", "能力任务"); Divider().frame(height: 28); stat("\(ChinCapability.all.count)", "能力方向") }.padding().background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: ChinRadius.panel))
                    Text("学习闭环：学方法 → 做任务 → 写作品 → 看错因 → 再迁移").font(.caption).foregroundStyle(.pink).multilineTextAlignment(.center).padding(.vertical, ChinSpacing.sm)
                    Text("ChinTop · 语文登顶  v1.0.0\n本地保存学习轨迹，数据只保留在本设备。").font(.caption).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.45)).padding(.vertical, ChinSpacing.xl)
                    Button(action: onEnter) { Label("开启语文登顶之旅", systemImage: "arrow.right").font(.headline).frame(maxWidth: .infinity).padding().background(.pink, in: RoundedRectangle(cornerRadius: ChinRadius.panel)).foregroundStyle(.white) }.padding(.bottom, ChinSpacing.page)
                }.padding(.horizontal, ChinSpacing.page).frame(maxWidth: 600)
            }
        }
    }
    private func stat(_ value: String, _ label: String) -> some View { VStack { Text(value).font(.headline).foregroundStyle(.pink); Text(label).font(.caption).foregroundStyle(.white.opacity(0.6)) }.frame(maxWidth: .infinity) }
}
