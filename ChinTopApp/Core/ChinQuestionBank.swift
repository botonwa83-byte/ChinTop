import Foundation

public enum ChinQuestionImportance: String, Codable, CaseIterable, Hashable { case core, supporting, `extension` }
public enum ChinQuestionDifficulty: String, Codable, CaseIterable, Hashable { case foundation, developing, challenge }
public enum ChinQuestionSourceKind: String, Codable, CaseIterable, Hashable { case localCurated, pendingVerification }

public struct ChinKnowledgePoint: Codable, Hashable, Identifiable {
    public let id: String; public let moduleID: String; public let title: String; public let grades: Set<ChinGradeLevel>; public let importance: ChinQuestionImportance
    public init(id: String, moduleID: String, title: String, grades: Set<ChinGradeLevel>, importance: ChinQuestionImportance) { self.id=id; self.moduleID=moduleID; self.title=title; self.grades=grades; self.importance=importance }
}

public struct ChinQuestion: Codable, Hashable, Identifiable {
    public let id: String; public let moduleID: String; public let grade: ChinGradeLevel; public let knowledgePointID: String; public let importance: ChinQuestionImportance; public let difficulty: ChinQuestionDifficulty; public let prompt: String; public let choices: [String]; public let answerIndex: Int; public let explanation: String; public let source: String; public let sourceKind: ChinQuestionSourceKind
}

/// 题库数据层：知识点目录与人工编写题目（经六轮扩充至 535 道：小学 258、初中 277）。
/// 第五轮为模块覆盖修正：补齐此前未覆盖的古诗词鉴赏模块（小学/初中共 8 个知识点），
/// 并同步补齐现代文阅读、综合性学习、作文与文言文中题量最薄的知识点。
/// 第六轮为按知识点均衡扩容：33 个知识点按覆盖学段整体加厚（两学段知识点各 +4、
/// 单学段知识点 +3 或 +2），共 +112 道，使每个知识点的练习量都能撑起一轮巩固。
/// 题量按知识点重要性权重配给（core:supporting:extension = 4:3:2 下限），测试以权重断言守护。
/// 内容红线：每题只考一个主知识点；答案与解析必须正确；来源统一诚实标注，
/// 不宣称真题、名校题或官方题库。
public enum ChinQuestionBank {

    // MARK: - 知识点目录（模块"覆盖知识点"与练习筛选器的唯一数据源）

    public static let knowledgePointCatalog: [ChinKnowledgePoint] = [
        // 现代文阅读
        kp("reading.character", "reading", "人物形象与细节", .core),
        kp("reading.evidence", "reading", "证据与信息提取", .core),
        kp("reading.structure", "reading", "结构·线索·思路", .core),
        kp("reading.title", "reading", "标题含义", .supporting),
        kp("reading.environment", "reading", "环境描写", .supporting, grades: [.primary]),
        kp("reading.language", "reading", "语言赏析", .supporting),
        kp("reading.expository", "reading", "说明文阅读", .supporting),
        kp("reading.argumentative", "reading", "议论文阅读", .supporting, grades: [.middle]),
        kp("reading.inquiry", "reading", "开放探究", .extension),
        kp("reading.strategy", "reading", "阅读策略", .extension, grades: [.primary]),
        // 文言文解码
        kp("classical.word", "classical", "实词（通假·古今异义·活用）", .core),
        kp("classical.function", "classical", "虚词", .core, grades: [.middle]),
        kp("classical.sentence", "classical", "特殊句式", .core, grades: [.middle]),
        kp("classical.translation", "classical", "翻译", .core, grades: [.middle]),
        kp("classical.summary", "classical", "内容概括与人物", .supporting),
        kp("classical.appreciation", "classical", "写法与主旨", .supporting, grades: [.middle]),
        // 古诗词鉴赏
        kp("poetry.imagery", "poetry", "意象与画面", .core),
        kp("poetry.word", "poetry", "炼字炼句", .core),
        kp("poetry.technique", "poetry", "表达技巧", .core),
        kp("poetry.emotion", "poetry", "思想感情", .core),
        // 考场作文升格
        kp("writing.topic", "writing", "审题与选材", .core),
        kp("writing.detail", "writing", "细节描写", .core),
        kp("writing.structure", "writing", "结构与首尾", .core),
        kp("writing.language", "writing", "语言升格与修改", .supporting, grades: [.primary]),
        kp("writing.application", "writing", "应用文写作", .supporting),
        kp("writing.argument", "writing", "材料立意与论证", .extension, grades: [.middle]),
        // 综合性学习与材料题
        kp("integrated.chart", "integrated", "图表解读", .core),
        kp("integrated.oral", "integrated", "口语交际与采访", .core, grades: [.primary]),
        kp("integrated.slogan", "integrated", "标语·对联·徽标", .supporting),
        kp("integrated.news", "integrated", "新闻与标题", .supporting, grades: [.primary]),
        kp("integrated.activity", "integrated", "活动方案与通知", .supporting, grades: [.primary]),
        kp("integrated.language", "integrated", "病句与标点", .supporting),
        kp("integrated.material", "integrated", "材料探究与跨文本", .extension, grades: [.middle])
    ]

    private static func kp(_ id: String, _ module: String, _ title: String, _ importance: ChinQuestionImportance, grades: Set<ChinGradeLevel> = Set(ChinGradeLevel.allCases)) -> ChinKnowledgePoint {
        ChinKnowledgePoint(id: id, moduleID: module, title: title, grades: grades, importance: importance)
    }

    // MARK: - 查询接口

    /// 题量按重要性权重配给：每个知识点在其覆盖学段内 core ≥ 4、supporting ≥ 3、extension ≥ 2。
    public static func targetCount(importance: ChinQuestionImportance) -> Int {
        switch importance {
        case .core: return 4
        case .supporting: return 3
        case .extension: return 2
        }
    }

    /// 免费档划线常量：未解锁时每个专题/知识点只开放前 freeQuestionCount 题（放在数组前部）。
    /// 改动此常量必须同步跑 testFreeTierPolicy，保证免费体验与内购划线一致。
    public static let freeQuestionCount = 3

    public static let all: [ChinQuestion] = primaryReading + middleReading + primaryClassical + middleClassical + primaryPoetry + middlePoetry + primaryWriting + middleWriting + primaryIntegrated + middleIntegrated + batch1ReadingAndClassical + batch2PoetryAndWriting + batch3Integrated + batch4ReadingAndClassical + batch5PoetryAndWriting + batch6Integrated + supplementJunior + supplementPrimary + supplementRoundFive + supplementRoundSix

    /// 过滤结果与知识点索引缓存：题目列表在 body 里会被反复求值，避免每次全表扫描。
    private static var questionFilterCache: [String: [ChinQuestion]] = [:]
    private static var knowledgePointIndex: [String: ChinKnowledgePoint]?
    private static let bankLock = NSLock()

    public static func questions(moduleID: String? = nil, grade: ChinGradeLevel, knowledgePointID: String? = nil, importance: ChinQuestionImportance? = nil) -> [ChinQuestion] {
        let cacheKey = "\(moduleID ?? "-")|\(grade.rawValue)|\(knowledgePointID ?? "-")|\(importance?.rawValue ?? "-")"
        bankLock.lock()
        if let cached = questionFilterCache[cacheKey] { bankLock.unlock(); return cached }
        bankLock.unlock()
        let value = all.filter { ($0.moduleID == moduleID || moduleID == nil) && $0.grade == grade && ($0.knowledgePointID == knowledgePointID || knowledgePointID == nil) && ($0.importance == importance || importance == nil) }
        bankLock.lock()
        questionFilterCache[cacheKey] = value
        bankLock.unlock()
        return value
    }
    public static func knowledgePoints(moduleID: String, grade: ChinGradeLevel) -> [ChinKnowledgePoint] { knowledgePointCatalog.filter { $0.moduleID == moduleID && $0.grades.contains(grade) } }
    public static func knowledgePoint(id: String) -> ChinKnowledgePoint? {
        bankLock.lock()
        if knowledgePointIndex == nil {
            knowledgePointIndex = Dictionary(uniqueKeysWithValues: knowledgePointCatalog.map { ($0.id, $0) })
        }
        let value = knowledgePointIndex?[id]
        bankLock.unlock()
        return value
    }

    private static let curatedSource = "本地精选练习 · 来源待核验"

    private static func q(_ id: String, _ module: String, _ grade: ChinGradeLevel, _ point: String, _ difficulty: ChinQuestionDifficulty, _ prompt: String, _ choices: [String], _ answer: Int, _ explanation: String) -> ChinQuestion {
        ChinQuestion(id: id, moduleID: module, grade: grade, knowledgePointID: point, importance: knowledgePoint(id: point)?.importance ?? .supporting, difficulty: difficulty, prompt: prompt, choices: choices, answerIndex: answer, explanation: explanation, source: curatedSource, sourceKind: .pendingVerification)
    }

    // MARK: - 小学高年级 · 现代文阅读（18）

    private static let primaryReading: [ChinQuestion] = [
        q("primary-reading-01","reading",.primary,"reading.character",.foundation,"“奶奶把最后一块年糕夹到我碗里，自己只喝了一口粥。”这处细节主要表现？",["奶奶疼爱孩子、愿意付出","奶奶不喜欢年糕","年糕味道不好","奶奶正在减肥"],0,"把最后一块留给孩子、自己少吃，是关爱的具体行动。"),
        q("primary-reading-02","reading",.primary,"reading.character",.developing,"“我”第一次演讲声音发抖，第二次能看着同学讲完。这个变化说明？",["实践和准备能增强自信","演讲稿内容变短了","同学不再认真听讲","第一次演讲没有意义"],0,"前后状态对比，表现反复练习带来的成长。"),
        q("primary-reading-03","reading",.primary,"reading.environment",.foundation,"作者写“操场空了，只剩扫帚划过地面的沙沙声”，主要营造？",["放学后的安静氛围","比赛即将开始的热烈","暴雨来临的紧张","节日庆典的喜悦"],0,"空操场和细小声音突出环境的安静。"),
        q("primary-reading-04","reading",.primary,"reading.character",.foundation,"“他没有解释，只把修好的自行车推到我面前。”这句话更突出人物的？",["少说多做、真诚负责","冷漠自私、拒绝沟通","胆小害怕、逃避责任","骄傲自满、炫耀技能"],0,"行动代替解释，修车行为体现负责和真诚。"),
        q("primary-reading-05","reading",.primary,"reading.language",.foundation,"将“雨来得很急，大家赶紧收衣服”改成“雨像一张突然落下的帘子”，表达效果是？",["运用比喻，使雨势突然、急促更具体","改变了事件发生时间","说明衣服质量很好","使句子变成说明文"],0,"比喻把抽象的雨势转为可感的画面。"),
        q("primary-reading-06","reading",.primary,"reading.evidence",.foundation,"概括一段写‘同学们分工清理校园花坛’的文字，最准确的是？",["同学们分工合作清理校园花坛","花坛里有很多花","同学们喜欢在校园玩耍","校园面积很大"],0,"概括保留人物、事件和结果，删去无关细节。"),
        q("primary-reading-07","reading",.primary,"reading.character",.foundation,"雨停了，屋檐还在滴水。小明把唯一的雨伞递给同学，自己跑进了雨幕。\n这段文字主要表现小明怎样的品质？",["乐于助人","胆小怕事","粗心大意","喜欢冒险"],0,"递伞和自己淋雨是直接证据，表现了小明愿意帮助同学。"),
        q("primary-reading-08","reading",.primary,"reading.environment",.developing,"“月光从窗帘缝里钻进来，照在那本摊开的日记上。”这句话在文中的作用最可能是？",["交代故事发生的时间并营造安静氛围","说明天气即将下雨","介绍日记的作者","推动人物快速离开"],0,"月光提示夜晚，细腻的环境描写也烘托了安静的氛围。"),
        q("primary-reading-09","reading",.primary,"reading.structure",.developing,"文章开头写“我”不愿学骑车，结尾写“我”主动教妹妹。最恰当的概括是？",["通过前后变化表现成长","说明骑车非常危险","强调妹妹比我聪明","首尾内容没有关系"],0,"人物态度由拒绝到主动，前后对比表现了责任感和成长。"),
        q("primary-reading-10","reading",.primary,"reading.evidence",.foundation,"“妈妈摸了摸我的额头，转身去拿体温计。”从这句话可以知道？",["妈妈很关心“我”的身体","妈妈想出门散步","体温计坏了","“我”正在睡觉"],0,"摸额头、拿体温计是关心身体的具体动作。"),
        q("primary-reading-11","reading",.primary,"reading.character",.foundation,"同桌把摔倒的小朋友扶起来，还帮他拍掉身上的土。可以看出同桌？",["乐于助人、细心","喜欢管闲事","自己不小心摔倒","想快点回家"],0,"扶起并拍土两个动作，表现乐于助人和细心。"),
        q("primary-reading-12","reading",.primary,"reading.environment",.foundation,"“太阳刚出来，荷叶上的露珠闪闪发亮。”这句环境描写交代的时间是？",["清晨","中午","傍晚","深夜"],0,"太阳刚出来、露珠未散，是清晨的典型景象。"),
        q("primary-reading-13","reading",.primary,"reading.language",.foundation,"“小溪唱着歌向前跑去”运用的修辞手法是？",["拟人","比喻","排比","反问"],0,"把溪水流动当作人唱歌、奔跑，赋予小溪人的动作。"),
        q("primary-reading-14","reading",.primary,"reading.structure",.foundation,"文章按“春、夏、秋、冬”的顺序写校园的景色，这样的顺序是？",["时间顺序","空间顺序","倒叙","插叙"],0,"春夏秋冬是明显的时间推移标志。"),
        q("primary-reading-15","reading",.primary,"reading.title",.developing,"标题《一盏不灭的灯》中“不灭”最可能指？",["某种精神或爱一直在延续","灯泡质量非常好","故事里从不停电","灯一直开着很浪费电"],0,"标题常有深层含义，“不灭”多指精神、情感的延续。"),
        q("primary-reading-16","reading",.primary,"reading.inquiry",.developing,"读完《愚公移山》，联系生活，最合理的启发是？",["认定目标后坚持行动，困难就可能被克服","搬山是解决问题的唯一办法","年纪大的人不能做成事情","遇到困难要马上放弃"],0,"愚公面对巨大困难持续行动，启发是坚持与行动。"),
        q("primary-reading-17","reading",.primary,"reading.expository",.developing,"说明文写“鲸不是鱼，而是哺乳动物”，下列哪条证据最有效？",["鲸用肺呼吸、胎生哺乳","鲸生活在水里","鲸的体型很大","鲸会跃出水面"],0,"肺呼吸、胎生是哺乳动物的科学特征，是分类的直接证据。"),
        q("primary-reading-18","reading",.primary,"reading.strategy",.foundation,"阅读一篇新文章前，先看标题和首尾段的好处是？",["快速形成整体预测，再回文验证细节","可以完全不读中间内容","只需记住作者姓名","能直接猜出所有答案"],0,"标题和首尾帮助建立阅读框架，但仍需回文验证。")
    ]

    // MARK: - 初中 · 现代文阅读（16）

    private static let middleReading: [ChinQuestion] = [
        q("middle-reading-01","reading",.middle,"reading.title",.developing,"题目《窗台上的薄荷》既指植物，也可能象征？",["平凡生活中持续生长的希望","一种昂贵的装饰品","主人公害怕阳光","故事发生在花店"],0,"薄荷在窗台生长可寄托坚韧、清新的生活希望。"),
        q("middle-reading-02","reading",.middle,"reading.expository",.developing,"说明文介绍桥梁抗震，先说地震危害，再说减震装置，最后列实验数据。说明顺序是？",["逻辑顺序","时间顺序","空间顺序","倒叙顺序"],0,"按问题、原理、数据的逻辑关系展开。"),
        q("middle-reading-03","reading",.middle,"reading.structure",.developing,"文章反复出现“那盏灯”，最可能的作用是？",["作为线索串联事件并寄托人物情感","说明电费很便宜","表示故事总在白天发生","代替所有人物描写"],0,"反复出现的意象可以串联情节并承载情感。"),
        q("middle-reading-04","reading",.middle,"reading.inquiry",.foundation,"面对开放探究题，答案最重要的是？",["观点明确，并结合文本证据说明理由","只写‘我觉得是这样’","抄写题目中的一个词","只写与文本无关的经历"],0,"开放题仍要回到文本，用证据支撑观点。"),
        q("middle-reading-05","reading",.middle,"reading.argumentative",.developing,"议论文先提出‘失败并不可怕’，接着分析失败原因，最后给出改进建议。结构是？",["提出问题—分析问题—解决问题","总分总但没有观点","按空间位置说明","先叙事后写景"],0,"观点、原因、建议分别对应议论文常见论证结构。"),
        q("middle-reading-06","reading",.middle,"reading.expository",.developing,"说明文写“竹子能保持水土”，下列哪项属于支持该观点的有效证据？",["竹子的根系发达，能固定土壤","竹叶颜色很鲜艳","很多人喜欢竹笋","竹子常被画进国画"],0,"根系发达与保持水土有因果关系，是直接科学证据。"),
        q("middle-reading-07","reading",.middle,"reading.argumentative",.foundation,"议论文观点为“阅读要有选择”。下列论据最有力的是？",["鲁迅一生博览群书，也会根据需要精读","我同桌喜欢看漫画","图书馆今天人很多","这本书的封面很漂亮"],0,"名人阅读经验能具体证明应按需要选择并精读。"),
        q("middle-reading-08","reading",.middle,"reading.evidence",.developing,"阅读时遇到“这件事”指代不明，最有效的做法是？",["回看前文，寻找与语法和语义都匹配的内容","只看距离最近的名词","跳过整段不读","凭自己的生活经验猜"],0,"指代题要结合前文语境和句法关系确定指向。"),
        q("middle-reading-09","reading",.middle,"reading.title",.developing,"标题“迟到的掌声”既指演出结束后的掌声，也暗示？",["主人公得到认可来得很晚","观众没有听懂演出","演出开始得太早","掌声声音很小"],0,"标题有表层和深层含义，深层指认可经历了等待。"),
        q("middle-reading-10","reading",.middle,"reading.character",.developing,"“他把奖状轻轻折好，放进书包最里层。”从动作中可以推断他？",["珍惜荣誉又不张扬","不喜欢参加比赛","准备马上丢掉奖状","害怕同学看见书包"],0,"轻轻折好、放在最里层体现珍惜，同时没有炫耀。"),
        q("middle-reading-11","reading",.middle,"reading.argumentative",.challenge,"议论文论点是“挫折能磨炼人”，下列哪则材料作为论据最不恰当？",["一位运动员受伤后坚持康复训练再夺冠军","司马迁遭受宫刑后完成《史记》","某人一次考试失利后从此放弃所有学习","贝多芬失聪后坚持创作"],2,"该材料与论点相反，证明的是被挫折击垮，不能支撑“磨炼人”。"),
        q("middle-reading-12","reading",.middle,"reading.expository",.challenge,"说明文“桥长约50米”中“约”字能否删去？最准确的理解是？",["不能，“约”表示估计，删去后与事实不符，体现说明文语言的准确性","能，数字不影响理解","能，删去后更简洁","不能，因为删去后句子不通顺"],0,"“约”限制精确程度，是说明文语言准确性的典型考点。"),
        q("middle-reading-13","reading",.middle,"reading.language",.challenge,"赏析“春风又绿江南岸”中“绿”字，最完整的是？",["“绿”形容词用作动词，写出春风吹拂、江南渐绿的过程，画面鲜活","“绿”就是一种颜色","“绿”字笔画很简单","“绿”说明诗人喜欢绿色"],0,"要把字放回语境，说明词性活用、画面变化和表达效果。"),
        q("middle-reading-14","reading",.middle,"reading.structure",.developing,"文章先写“我”误解父亲，再写发现真相后的愧疚，最后表达对父亲的理解。这种写法的好处是？",["欲扬先抑，使情感转变更真实、更打动人","只是为了凑足字数","故意让故事更混乱","与主题没有关系"],0,"先抑后扬制造反差，情感变化更有层次。"),
        q("middle-reading-15","reading",.middle,"reading.title",.developing,"标题《补丁》既指衣服上的补丁，又暗示？",["外婆用勤劳和节俭缝补起一家人的生活","衣服破了很多洞","商店里买不到新衣服","主人公不喜欢新衣服"],0,"表层写衣物，深层写人物质朴的持家之爱。"),
        q("middle-reading-16","reading",.middle,"reading.character",.developing,"“父亲把伞倾向我这边，自己半边肩膀全湿了。”这一细节表现了？",["父亲把孩子的需要放在自己之前","父亲不知道外面下雨了","那把伞实在太小","父亲喜欢淋雨"],0,"伞的倾斜方向和湿透的肩膀是父爱的具体证据。")
    ]

    // MARK: - 小学高年级 · 文言文（6）

    private static let primaryClassical: [ChinQuestion] = [
        q("primary-classical-01","classical",.primary,"classical.word",.foundation,"“温故而知新”中“故”指？",["旧的知识","故事","事故","故意"],0,"‘故’与‘新’相对，指已经学过的知识。"),
        q("primary-classical-02","classical",.primary,"classical.word",.foundation,"“吾日三省吾身”中“省”的意思是？",["反省、检查","节省","省略","行政区域"],0,"‘三省’是多次反省自己的行为。"),
        q("primary-classical-03","classical",.primary,"classical.word",.foundation,"“陈太丘与友期行，期日中”中“期”的意思是？",["约定","期限","期待","周期"],0,"‘期行’表示约定一同出行。"),
        q("primary-classical-04","classical",.primary,"classical.word",.developing,"“见贤思齐焉”中“齐”的意思是？",["看齐、向他看齐","整齐","齐国","一起"],0,"见到贤人就想着向他看齐。"),
        q("primary-classical-05","classical",.primary,"classical.word",.developing,"“学而时习之，不亦说乎”中“说”的意思是？",["同“悦”，愉快","说明","劝说","谈论"],0,"“说”通“悦”，表示高兴。"),
        q("primary-classical-06","classical",.primary,"classical.summary",.foundation,"《愚公移山》中愚公坚持移山，最能体现的品质是？",["目标坚定、坚持不懈","急功近利、喜欢炫耀","害怕困难、听天由命","只相信运气"],0,"面对巨大困难仍持续行动，体现坚持和信念。")
    ]

    // MARK: - 初中 · 文言文（16）

    private static let middleClassical: [ChinQuestion] = [
        q("middle-classical-01","classical",.middle,"classical.appreciation",.developing,"“山不在高，有仙则名；水不在深，有龙则灵。”这两句运用了什么写法？",["比兴","排比","夸张","反问"],0,"先比山水，再引出陋室，以山水起兴，属于比兴写法。"),
        q("middle-classical-02","classical",.middle,"classical.word",.foundation,"“斯是陋室，惟吾德馨”中“馨”的意思是？",["能散布很远的香气，这里指品德高尚","声音洪亮","房间宽敞","名声很大"],0,"馨本义为香气远播，文中借指品德高尚。"),
        q("middle-classical-03","classical",.middle,"classical.summary",.developing,"《爱莲说》中作者以莲自况，最能概括其品格的是？",["不慕荣利、洁身自好","追逐名利、随波逐流","孤僻冷漠、拒绝交往","刚愎自用、目空一切"],0,"‘出淤泥而不染’等句表现洁身自好、不与世俗同流合污。"),
        q("middle-classical-04","classical",.middle,"classical.function",.developing,"“醉能同其乐，醒能述以文者，太守也。”中的“以”相当于？",["把、用","因为","从","如果"],0,"‘述以文’是用文章记述这件事，‘以’为介词‘用’。"),
        q("middle-classical-05","classical",.middle,"classical.sentence",.developing,"“何以战”按现代汉语语序应理解为？",["凭什么作战","为什么结束战争","用什么时间作战","哪里可以战斗"],0,"‘何以’是宾语前置，正常语序为‘以何战’。"),
        q("middle-classical-06","classical",.middle,"classical.sentence",.foundation,"“莲，花之君子者也”属于？",["判断句","被动句","省略句","反问句"],0,"‘……者也’是典型判断句标志。"),
        q("middle-classical-07","classical",.middle,"classical.translation",.developing,"把“肉食者鄙，未能远谋”翻译为？",["当权的人目光短浅，不能深谋远虑","吃肉的人很粗俗，不能走远","贵族不吃肉，所以没有计划","士兵看不起远方的谋士"],0,"‘鄙’为目光短浅，‘远谋’为深谋远虑。"),
        q("middle-classical-08","classical",.middle,"classical.sentence",.developing,"“吾谁与归”中“谁”前置，正常语序是？",["吾与谁归","谁归于吾","吾归与谁之","与吾归谁"],0,"疑问代词作宾语前置，正常语序为‘我同谁一道归去’。"),
        q("middle-classical-09","classical",.middle,"classical.function",.developing,"“虽我之死，有子存焉”中“虽”的意思是？",["即使","虽然已经","虽说","唯独"],0,"句中表达假设让步，译为‘即使’。"),
        q("middle-classical-10","classical",.middle,"classical.summary",.developing,"文言文内容概括题最可靠的依据是？",["结合人物行为和关键语句概括","只凭现代生活经验","只看最后一句","把译文改写成感想"],0,"人物行为和关键语句共同支撑内容与主旨。"),
        q("middle-classical-11","classical",.middle,"classical.translation",.challenge,"翻译文言句时遇到省略成分，应？",["根据上下文补出省略的主语或宾语","完全按照字面硬译","删除整句","只翻译虚词"],0,"省略成分需要结合语境补足，译文才通顺准确。"),
        q("middle-classical-12","classical",.middle,"classical.word",.foundation,"“山不在高，有仙则名”中“名”的意思是？",["出名、有名","名字","命名","名次"],0,"结合山因有仙而闻名的语境，取‘出名’义。"),
        q("middle-classical-13","classical",.middle,"classical.translation",.challenge,"把“先天下之忧而忧，后天下之乐而乐”翻译准确的是？",["在天下人忧虑之前忧虑，在天下人快乐之后才快乐","先忧愁，再和天下人一起快乐","把天下的忧愁和快乐放在后面","先替自己忧虑，最后享受快乐"],0,"‘先’和‘后’分别表示在……之前、在……之后。"),
        q("middle-classical-14","classical",.middle,"classical.word",.developing,"“一狼洞其中”中“洞”是名词作动词，意思是？",["打洞","洞穴","观察洞口","躲进洞里"],0,"‘洞’在句中带宾语‘其中’，活用为‘打洞’。"),
        q("middle-classical-15","classical",.middle,"classical.word",.foundation,"“屠自后断其股”中“股”指？",["大腿","股票","屁股","腰部"],0,"古汉语中‘股’常指大腿，不能按现代义理解。"),
        q("middle-classical-16","classical",.middle,"classical.summary",.developing,"阅读《陈太丘与友期行》，陈太丘的友人最终‘惭’的原因是？",["失约在先，又在孩子面前失礼","孩子拒绝给他开门","陈太丘没有带他同行","天气突然变坏"],0,"友人先失约后骂人，面对元方的有理反驳而惭愧。")
    ]

    // MARK: - 小学高年级 · 古诗词（10）

    private static let primaryPoetry: [ChinQuestion] = [
        q("primary-poetry-01","poetry",.primary,"poetry.imagery",.foundation,"“几处早莺争暖树，谁家新燕啄春泥”写的是？",["早春生机","深秋萧瑟","冬日严寒","盛夏炎热"],0,"早莺、新燕是春回大地的典型意象。"),
        q("primary-poetry-02","poetry",.primary,"poetry.word",.developing,"“小荷才露尖尖角，早有蜻蜓立上头”中的“才”“早”形成？",["呼应，表现初夏新荷的生机","夸张，说明荷叶很大","用典，表现思乡","拟人，表现悲伤"],0,"一‘才’一‘早’写出新荷初露、蜻蜓相伴的灵动。"),
        q("primary-poetry-03","poetry",.primary,"poetry.emotion",.foundation,"“孤帆远影碧空尽，唯见长江天际流”表达的情感是？",["送别友人的依依不舍","归乡后的喜悦","战场上的豪迈","田园生活的闲适"],0,"目送孤帆远去，仍久久凝望江水，表现不舍。"),
        q("primary-poetry-04","poetry",.primary,"poetry.technique",.foundation,"“不知细叶谁裁出，二月春风似剪刀”把春风比作剪刀，作用是？",["把无形的春风写得可感，表现春天的巧妙和生机","说明春风真的会剪东西","表现诗人害怕春风","交代作者使用工具"],0,"比喻使春风化无形为有形，突出春意和想象力。"),
        q("primary-poetry-05","poetry",.primary,"poetry.technique",.developing,"古诗画面题中写‘小桥、流水、夕阳’，还应补充？",["按空间关系组织成完整场景，并点出氛围","只列出三个名词","只写作者朝代","改成现代歌词"],0,"要有画面组合和氛围判断，不能只罗列意象。"),
        q("primary-poetry-06","poetry",.primary,"poetry.word",.developing,"比较“随风潜入夜”和“润物细无声”，两句共同突出春雨怎样的特点？",["悄无声息、滋润万物","来势猛烈、声音洪大","只在夜间出现","使万物迅速枯萎"],0,"‘潜’‘无声’都强调春雨细密而不扰人。"),
        q("primary-poetry-07","poetry",.primary,"poetry.emotion",.foundation,"“海内存知己，天涯若比邻”表达的情感是？",["对友人的宽慰和旷达胸襟","对秋景的悲叹","对战争的恐惧","对田园生活的向往"],0,"把远隔天涯的友人视为知己，表现旷达的送别情怀。"),
        q("primary-poetry-08","poetry",.primary,"poetry.imagery",.foundation,"“儿童散学归来早，忙趁东风放纸鸢”描绘的画面是？",["孩子们放学后趁着春风快乐地放风筝","孩子们在课堂上背书","老人在树下休息","春天刮起了大风"],0,"散学、忙趁、放纸鸢写出儿童迎春嬉戏的轻快画面。"),
        q("primary-poetry-09","poetry",.primary,"poetry.emotion",.foundation,"“谁知盘中餐，粒粒皆辛苦”表达的主要情感是？",["对农民辛勤劳作的体恤，劝人珍惜粮食","描写米饭很香","夸耀自己会种地","抱怨天气太热"],0,"由‘粒粒皆辛苦’直接点出对劳作艰辛的体恤。"),
        q("primary-poetry-10","poetry",.primary,"poetry.emotion",.foundation,"“牧童骑黄牛，歌声振林樾”描绘的牧童形象是？",["悠闲自在、天真快乐","悲伤孤独","紧张害怕","疲惫不堪"],0,"骑牛高歌，写出牧童无拘无束的悠然情趣。")
    ]

    // MARK: - 初中 · 古诗词（12）

    private static let middlePoetry: [ChinQuestion] = [
        q("middle-poetry-01","poetry",.middle,"poetry.technique",.challenge,"“无边落木萧萧下，不尽长江滚滚来”使用了？",["对偶和动静结合，表现秋景的苍凉壮阔","设问和用典，表现欢快","拟人和夸张，表现闺怨","借代和反问，表现闲适"],0,"上下句结构整齐，落木与江水共同构成雄浑秋景。"),
        q("middle-poetry-02","poetry",.middle,"poetry.imagery",.developing,"“正是江南好风景，落花时节又逢君”中的“落花”暗示？",["美好事物衰败、个人身世的感慨","春天刚刚开始","诗人准备赏花","江南天气炎热"],0,"落花既是暮春景象，也寄托时代和身世的伤感。"),
        q("middle-poetry-03","poetry",.middle,"poetry.word",.developing,"炼字题解释“炼”字时，最完整的答案应包括？",["字面义、画面义、表达效果和情感","只写字典解释","只写‘生动形象’","只翻译整首诗"],0,"要把字放入语境，说明画面、手法及情感作用。"),
        q("middle-poetry-04","poetry",.middle,"poetry.technique",.developing,"诗歌结尾写景但没有直接抒情，常见作用是？",["以景结情，含蓄地延长情感余韵","说明诗人忘记了主题","表示情感已经消失","只是为了押韵"],0,"景物承载情感，结尾留白能增强余味。"),
        q("middle-poetry-05","poetry",.middle,"poetry.technique",.developing,"“烽火连三月，家书抵万金”中“抵万金”使用了？",["夸张，突出家书的珍贵","比喻，说明家书能兑换金钱","拟人，写烽火有感情","反问，表达疑惑"],0,"以夸张写战乱中家书难得和思亲之深。"),
        q("middle-poetry-06","poetry",.middle,"poetry.emotion",.foundation,"“长风破浪会有时，直挂云帆济沧海”表达了？",["对未来理想的坚定信心","对朋友离别的哀伤","对春景的赞美","对战争残酷的恐惧"],0,"破浪、济海表现冲破困境、实现理想的信念。"),
        q("middle-poetry-07","poetry",.middle,"poetry.imagery",.foundation,"“大漠孤烟直，长河落日圆”描绘的意境特点是？",["苍凉壮阔","清新明丽","幽静凄冷","繁华热闹"],0,"大漠、孤烟、长河、落日构成开阔而苍凉的边塞画面。"),
        q("middle-poetry-08","poetry",.middle,"poetry.word",.challenge,"“海日生残夜，江春入旧年”中“生”“入”写出了？",["新旧交替、时光流转","江水上涨、海面下降","诗人早起、夜晚归来","海边春天特别寒冷"],0,"‘生’和‘入’赋予日、春以动态，表现时序更替。"),
        q("middle-poetry-09","poetry",.middle,"poetry.technique",.developing,"诗句“感时花溅泪，恨别鸟惊心”主要运用了？",["借景抒情、移情于物","直抒胸臆","用典","夸张说明"],0,"花鸟本无情，诗人把自己的感受投射到景物上。"),
        q("middle-poetry-10","poetry",.middle,"poetry.imagery",.foundation,"“枯藤老树昏鸦”连续使用多个意象，营造了怎样的氛围？",["凄清悲凉","欢快热烈","雄奇豪迈","明亮温暖"],0,"枯、老、昏等词共同构成秋暮羁旅的凄清氛围。"),
        q("middle-poetry-11","poetry",.middle,"poetry.emotion",.developing,"“会当凌绝顶，一览众山小”表达了诗人怎样的志向？",["勇于攀登、追求卓越","留恋山中景色","害怕高处危险","思念故乡亲人"],0,"登顶和俯视群山寄托了不畏艰难、积极进取的志向。"),
        q("middle-poetry-12","poetry",.middle,"poetry.emotion",.developing,"“落红不是无情物，化作春泥更护花”中“落红”寄托了诗人怎样的情怀？",["虽辞官仍关心国家、甘于奉献","对春花凋谢的怨恨","隐居山林的闲适","对功名利禄的追逐"],0,"落花化泥护花，借物抒写离开岗位后仍愿奉献的情怀。")
    ]

    // MARK: - 小学高年级 · 作文（14）

    private static let primaryWriting: [ChinQuestion] = [
        q("primary-writing-01","writing",.primary,"writing.topic",.foundation,"半命题作文‘我学会了____’，填入最容易写出完整事件的是？",["承担责任","开心","东西","一天"],0,"‘承担责任’有具体行动和变化，便于组织事件。"),
        q("primary-writing-02","writing",.primary,"writing.detail",.foundation,"记叙一件小事想突出‘感动’，最需要补写？",["人物当时的动作、语言和自己的心理变化","天气预报全文","与主题无关的景物清单","故事发生地的百科介绍"],0,"细节和心理变化能让情感真实可感。"),
        q("primary-writing-03","writing",.primary,"writing.structure",.developing,"下列开头最适合题目《一次特别的掌声》的是？",["掌声响起时，我才发现自己一直攥紧的手已经全是汗。","掌声是一种声音。","从前有一个人。","大家都知道掌声很重要。"],0,"从现场细节切入，设置悬念并直接进入事件。"),
        q("primary-writing-04","writing",.primary,"writing.structure",.developing,"文章写比赛失利后重新训练，结尾最能点题的是？",["我终于明白，真正的胜利是愿意从失败中重新出发。","比赛结束了，大家回家。","这一天的天气不错。","我以后也许会参加比赛。"],0,"结尾回扣失败与成长，明确升华中心。"),
        q("primary-writing-05","writing",.primary,"writing.language",.foundation,"将‘我很害怕’改得更具体，最合适的是？",["我盯着台下的黑压压一片，喉咙像被什么堵住了。","我真的非常害怕特别害怕","害怕是我的一种感觉","我觉得害怕这个词很好"],0,"视觉和身体感受把抽象情绪具体化。"),
        q("primary-writing-06","writing",.primary,"writing.structure",.foundation,"下列句子衔接最自然的是：我第一次做实验失败了。____我查资料重新操作。",["于是","虽然","例如","否则"],0,"后句是前句失败后的行动结果，‘于是’表因果承接。"),
        q("primary-writing-07","writing",.primary,"writing.language",.developing,"修改‘通过阅读名著，使我提高了写作能力’，正确的是？",["通过阅读名著，我提高了写作能力。","通过阅读名著，使我提高能力了写作。","阅读名著通过，使我提高了写作能力。","通过名著阅读，使我能力写作提高。"],0,"删去‘使’，让‘我’成为完整主语。"),
        q("primary-writing-08","writing",.primary,"writing.topic",.foundation,"作文题目为“那一次，我懂得了坚持”，下列选材最切题的是？",["练习长跑多次想放弃，最终完成比赛","周末和同学看了一场电影","介绍家乡的美食","描写一次生日聚会"],0,"反复练习、想放弃、最终完成能具体表现‘坚持’。"),
        q("primary-writing-09","writing",.primary,"writing.detail",.foundation,"记叙文中写人物紧张，最生动的细节是？",["他的手心出了汗，稿纸边角被捏出一道折痕","他很紧张","紧张是一个词","大家都知道他紧张"],0,"手心出汗、捏皱稿纸是可观察的动作细节。"),
        q("primary-writing-10","writing",.primary,"writing.structure",.developing,"“我推开门，风把院里的桂花香送了进来。”这句话适合作为？",["用环境描写自然引出回忆","议论文的论点","新闻标题","说明文定义"],0,"气味触发回忆，是记叙文常用的自然过渡。"),
        q("primary-writing-11","writing",.primary,"writing.structure",.foundation,"下列哪一组连接词最适合组织‘准备比赛—遇到困难—完成目标’？",["起初……后来……最终……","因为……但是……所以（前后无此关系）","首先……总之（缺少过程）","也许……据说……"],0,"三组词对应起始、转折发展和结果，能形成清晰时间线。"),
        q("primary-writing-12","writing",.primary,"writing.application",.foundation,"毕业前给敬爱的老师写赠言，最得体的一项是？",["老师，谢谢您六年的教导，您的鼓励让我变得更勇敢。","老师，您布置的作业太多了。","老师，再见，我终于不用上学了。","老师，这是我的新电话号码。"],0,"赠言要表达感谢与祝福，情感真挚、语气得体。"),
        q("primary-writing-13","writing",.primary,"writing.detail",.foundation,"要写课间十分钟的‘热闹’，最合适的细节是？",["教室里到处是笑声，几个男生围着棋桌争得面红耳赤","课间十分钟有十分钟","同学们都在教室里","下课铃响了又响"],0,"笑声和争棋的具体场面能让‘热闹’被看见。"),
        q("primary-writing-14","writing",.primary,"writing.language",.developing,"修改病句‘我估计他今天一定不会来了’，正确的是？",["我估计他今天不会来了。","我估计他今天一定不可能会来了。","他估计我今天一定不会来了。","我估计他一定他今天不会来了。"],0,"‘估计’与‘一定’前后矛盾，删去‘一定’，消除冲突。")
    ]

    // MARK: - 初中 · 作文（10）

    private static let middleWriting: [ChinQuestion] = [
        q("middle-writing-01","writing",.middle,"writing.application",.developing,"倡议书正文中最不可缺少的是？",["倡议内容、具体做法和号召","故事人物的对话","诗歌押韵","天气描写"],0,"应用文要让读者知道做什么、怎么做以及为什么行动。"),
        q("middle-writing-02","writing",.middle,"writing.argument",.developing,"材料说‘有人每天制定计划却从不执行’，最恰当的观点是？",["计划要具体，更要落实并及时调整","计划越长越容易成功","只要写计划就不用行动","所有计划都没有意义"],0,"既肯定计划作用，也指出执行和调整的重要性。"),
        q("middle-writing-03","writing",.middle,"writing.application",.foundation,"书信结尾格式正确的是？",["祝学习进步！\n你的同学：小林\n5月10日","小林收\n祝好\n校长","再见！\n5月10日\n尊敬的校长","谢谢观看。"],0,"书信结尾先祝颂，再署名和日期，格式清楚。"),
        q("middle-writing-04","writing",.middle,"writing.application",.foundation,"题目要求‘给校长写一封建议增加课外阅读时间的信’，开头最合适的是？",["尊敬的校长：您好！最近我发现同学们课外阅读时间较少……","校长你必须马上增加时间！","嘿，校长，最近怎么样？","我今天特别开心，因为天气很好。"],0,"书信要有称谓和礼貌问候，开头直接交代写信目的。"),
        q("middle-writing-05","writing",.middle,"writing.argument",.challenge,"多材料作文中，材料一讲‘失败后复盘’，材料二讲‘比赛后总结’，共同立意是？",["在总结反思中提升自己","比赛一定会失败","只有运动员需要总结","复盘就是重复做题"],0,"两则材料都强调经历之后的反思和改进。"),
        q("middle-writing-06","writing",.middle,"writing.application",.developing,"演讲稿结尾最有感染力的是？",["让我们从今天开始，每天阅读二十分钟，一起成为更好的自己！","以上就是全部内容。","我不知道还要说什么。","谢谢大家，也可以不执行。"],0,"演讲结尾应回扣主题并发出明确、积极的行动号召。"),
        q("middle-writing-07","writing",.middle,"writing.detail",.developing,"写景开头要服务于‘我等待朋友归来’的主题，最合适的是？",["夕阳一点点沉下去，站台的长椅被拉出长长的影子。","我家附近有很多树。","世界上有各种各样的天气。","景物描写可以写任何内容。"],0,"暮色和长影烘托等待的漫长与牵挂，环境服务于主题。"),
        q("middle-writing-08","writing",.middle,"writing.topic",.challenge,"任务驱动作文要求‘以班级名义写一封感谢食堂工作人员的公开信’，审题最关键的是？",["明确写信人身份、感谢对象和公开信的文体","把食堂菜谱全部列出来","只写自己最爱吃的菜","用诗歌形式表达"],0,"任务驱动题先锁定身份、对象、目的和文体四个要素。"),
        q("middle-writing-09","writing",.middle,"writing.structure",.developing,"记叙‘学游泳’，最应该详写的部分是？",["克服怕水、反复练习最终游起来的过程","去游泳馆路上的风景","买泳衣的经过","回家吃晚饭的内容"],0,"详略要服务中心，成长与突破的过程是主旨所在。"),
        q("middle-writing-10","writing",.middle,"writing.argument",.developing,"论点为“好奇心推动进步”，下列论据最合适的是？",["牛顿由苹果落地追问原因，最终发现万有引力","有的同学上课东张西望","我喜欢问为什么","好奇心有时会让人分心"],0,"名人事例能具体证明好奇心带来探索与发现。")
    ]

    // MARK: - 小学高年级 · 综合性学习（12）

    private static let primaryIntegrated: [ChinQuestion] = [
        q("primary-integrated-01","integrated",.primary,"integrated.slogan",.foundation,"某校开展‘名著阅读’活动，宣传语最恰当的是？",["与经典同行，为成长阅读","名著越厚越值得读","读书只为考试得分","大家必须买同一本书"],0,"宣传语简洁，有主题和号召力，不作绝对化要求。"),
        q("primary-integrated-02","integrated",.primary,"integrated.activity",.foundation,"班级准备开展‘整本书阅读’，下列活动安排最完整的是？",["制定书目—分组阅读—交流分享—成果展示","只发通知，不安排阅读","先评奖，再决定读什么","只让一名同学讲完全部内容"],0,"活动有准备、实施、交流和成果环节，流程完整。"),
        q("primary-integrated-03","integrated",.primary,"integrated.chart",.developing,"图表显示四年级借阅最多的是科普书，六年级借阅最多的是文学书。可以概括为？",["不同年级的阅读兴趣存在差异","所有学生都只喜欢科普书","文学书没有人阅读","年级越高阅读量一定越少"],0,"只概括图表呈现的类别差异，不作无依据推断。"),
        q("primary-integrated-04","integrated",.primary,"integrated.news",.foundation,"新闻标题‘小小讲解员走进博物馆’最核心的信息是？",["学生担任讲解员开展博物馆实践","博物馆即将关闭","讲解员都是成年人","学生参观了游乐园"],0,"标题抓住人物、地点和主要活动。"),
        q("primary-integrated-05","integrated",.primary,"integrated.slogan",.foundation,"为‘节约用水’设计宣传语，最恰当的是？",["珍惜每一滴水，共护清洁家园","水就是一种透明液体","我今天喝了两杯水","节水这件事以后再说"],0,"短句有对象、有行动号召，适合宣传。"),
        q("primary-integrated-06","integrated",.primary,"integrated.slogan",.developing,"徽标中有一本打开的书和一棵幼苗，最合理的寓意是？",["阅读滋养成长","学校只种树不读书","书本需要浇水","植物不能长大"],0,"书代表阅读，幼苗代表成长，组合表达阅读育人。"),
        q("primary-integrated-07","integrated",.primary,"integrated.oral",.developing,"采访图书管理员‘怎样提高借阅率’，问题应具体到？",["推荐书目、开放时间和借阅活动有哪些安排？","你觉得书好看吗？","图书馆是不是很大？","你今天心情如何？"],0,"问题覆盖可执行的措施，便于获得有效回答。"),
        q("primary-integrated-08","integrated",.primary,"integrated.activity",.foundation,"下列通知标题最规范的是？",["关于开展校园读书节活动的通知","快来看读书节啦","读书节我有话说","通知：大家注意一下"],0,"公文标题应明确事项和文种，语言简洁正式。"),
        q("primary-integrated-09","integrated",.primary,"integrated.language",.foundation,"把‘同学们都忍不住情不自禁地笑了’改为？",["同学们都忍不住笑了。","同学们都情不自禁忍不住笑了。","同学们忍不住都情不自禁地笑了。","同学们笑了忍不住。"],0,"‘忍不住’和‘情不自禁’语义重复，保留其一。"),
        q("primary-integrated-10","integrated",.primary,"integrated.oral",.foundation,"口语交际中劝同学不要在楼梯奔跑，最得体的是？",["楼梯人多容易摔倒，我们一起慢一点走，好吗？","你再跑就完了！","我不喜欢你这样做。","跑吧，反正与我无关。"],0,"说明风险、提出建议并使用商量语气，更容易被接受。"),
        q("primary-integrated-11","integrated",.primary,"integrated.news",.developing,"新闻导语包含‘时间、地点、人物、事件’四要素，最完整的是？",["5月10日，学校在报告厅举行读书节启动仪式。","读书节真有意思。","报告厅很大。","同学们都喜欢读书。"],0,"导语先交代时间、地点和核心事件，信息完整准确。"),
        q("primary-integrated-12","integrated",.primary,"integrated.activity",.foundation,"活动方案中‘邀请校外作家来校分享’属于哪一项？",["活动内容","活动口号","活动反馈","个人感想"],0,"邀请作家分享是活动要开展的具体内容。")
    ]

    // MARK: - 初中 · 综合性学习（6）

    private static let middleIntegrated: [ChinQuestion] = [
        q("middle-integrated-01","integrated",.middle,"integrated.material",.developing,"材料一提倡纸质阅读，材料二介绍有声阅读。综合两则材料应？",["根据场景选择合适方式，重视阅读效果","纸质和有声只能选一种","有声阅读完全没有价值","阅读只看数量不看理解"],0,"两种方式各有特点，核心是选择并获得有效阅读。"),
        q("middle-integrated-02","integrated",.middle,"integrated.slogan",.developing,"对联上联‘书山有路勤为径’，下联应是？",["学海无涯苦作舟","风吹草低见牛羊","海内存知己","明月何时照我还"],0,"上下联内容和结构相对，形成关于学习的完整对联。"),
        q("middle-integrated-03","integrated",.middle,"integrated.material",.developing,"跨文本阅读先分别概括，再比较异同，主要是为了？",["避免把一篇材料的信息误套到另一篇","让答案写得越长越好","只选择自己喜欢的材料","不用关注材料证据"],0,"分开理解再比较能保持证据边界，提升准确性。"),
        q("middle-integrated-04","integrated",.middle,"integrated.chart",.challenge,"某班调查显示：每天阅读20分钟的同学，语文测验平均分为88分；阅读不足10分钟的同学平均分为76分。最稳妥的结论是？",["在本次调查中，阅读时间较长的同学平均成绩更高","只要阅读20分钟就一定考满分","阅读时间是成绩唯一原因","所有同学都应每天阅读两小时"],0,"结论只能概括调查呈现的相关关系，不能夸大为必然因果。"),
        q("middle-integrated-05","integrated",.middle,"integrated.slogan",.challenge,"对联上联‘一片湖光春色好’，下联最合适的是？",["万家灯火夜景新","春风又绿江南岸","读书破万卷","山明水秀风光美"],0,"‘万家灯火夜景新’字数、结构和意境相对协调。"),
        q("middle-integrated-06","integrated",.middle,"integrated.language",.developing,"下列句子标点使用正确的一项是？",["老师问：“你今天为什么迟到？”","老师问：“你今天为什么迟到”？","老师问，“你今天为什么迟到”。","老师问“你今天为什么迟到”。"],0,"直接引语用冒号加引号，疑问语气词后的问号放在引号内。")
    ]

    // MARK: - 批次 1：现代文阅读 + 文言文（29）

    private static let batch1ReadingAndClassical: [ChinQuestion] = [
        // 小学 · 现代文阅读（11）
        q("primary-reading-19","reading",.primary,"reading.evidence",.foundation,"“弟弟踮起脚，把桌上的水杯轻轻推到妈妈手边。”这个细节说明弟弟？",["懂得关心妈妈","想玩水","个子很高","口渴了"],0,"踮脚推水杯是体贴妈妈的具体动作。"),
        q("primary-reading-20","reading",.primary,"reading.evidence",.developing,"读“快递员冒雪把包裹送到老人家门口”，最能支撑“负责”这一判断的证据是？",["冒雪仍按时送到","包裹很轻","老人住在楼上","快递车很新"],0,"天气恶劣仍完成送达，直接证明负责。"),
        q("primary-reading-21","reading",.primary,"reading.structure",.foundation,"文章先写“小时候怕黑”，再写“现在敢一个人走夜路”，这样写是为了？",["通过前后对比表现“我”变勇敢了","说明晚上很黑","告诉大家不要出门","介绍路灯的历史"],0,"前后对照突出人物的变化与成长。"),
        q("primary-reading-22","reading",.primary,"reading.structure",.developing,"段落之间用“从那以后”“又过了几年”连接，作用是？",["按时间推移把事件串起来，条理清楚","让文章更长","表示作者记不清了","与内容无关"],0,"时间标志词把事件组织成清晰的线索。"),
        q("primary-reading-23","reading",.primary,"reading.title",.developing,"标题《会飞的教室》用“会飞”是为了？",["激发想象，暗示这是一间充满梦想和创意的教室","教室真的有翅膀","说明窗外风很大","教室建在飞机上"],0,"非常规搭配制造悬念，引导读者联想主题。"),
        q("primary-reading-24","reading",.primary,"reading.title",.developing,"标题《手心里的温暖》中“温暖”最可能指？",["亲人或朋友给予的关爱","手心里握着热水袋","天气很暖和","手的温度很高"],0,"标题常用具体事物寄托抽象情感。"),
        q("primary-reading-25","reading",.primary,"reading.language",.developing,"“月亮像一条小船，挂在深蓝色的夜空里。”这样写的好处是？",["用比喻把月亮的形状和夜色写得具体、美丽","说明月亮会游泳","表示天要下雨了","让句子变得更长"],0,"比喻把月亮的样子变得可感、有画面。"),
        q("primary-reading-26","reading",.primary,"reading.expository",.developing,"说明文介绍“含羞草一碰就合拢”，这属于说明事物的？",["特点和原理","价格和产地","颜色和味道","种植历史"],0,"“一碰就合拢”是含羞草最突出的特性。"),
        q("primary-reading-27","reading",.primary,"reading.expository",.developing,"“这座塔高约30米，相当于10层楼那么高。”运用的说明方法是？",["列数字和作比较","打比方和拟人","排比和引用","设问和反问"],0,"“30米”是列数字，“相当于10层楼”是作比较。"),
        q("primary-reading-28","reading",.primary,"reading.inquiry",.developing,"读完整本书想推荐给别人，最有说服力的理由是？",["结合书中具体情节说出自己的收获","这本书很厚","封面很好看","别人都在读"],0,"推荐理由要有具体内容和个人体验支撑。"),
        q("primary-reading-29","reading",.primary,"reading.strategy",.developing,"阅读时遇到不认识的字词，最不影响理解大意的做法是？",["先根据上下文猜一猜，读完再查字典验证","立即停下逐个查字典","跳过整段不读","凭想象编一个意思"],0,"先猜读后查证，既保持阅读连贯又落实词义。"),
        // 初中 · 现代文阅读（10）
        q("middle-reading-17","reading",.middle,"reading.character",.developing,"“他蹲下身，把散落一地的书一本本捡起来，拍掉灰，按大小码好。”这一连串动作表现他？",["做事有条理、爱护物品","书是他自己的","动作很慢","他喜欢整理房间"],0,"捡起、拍灰、码好的顺序体现细致和条理。"),
        q("middle-reading-18","reading",.middle,"reading.character",.challenge,"文中母亲“转身进了厨房，再出来时眼圈微红，却笑着说菜马上好”。这一细节表现母亲？",["不愿让孩子看到自己的难过，强撑着安慰家人","切洋葱呛到了","厨房里太热","她不擅长表达"],0,"眼圈微红与笑容的反差，表现克制和爱护。"),
        q("middle-reading-19","reading",.middle,"reading.evidence",.developing,"论证“运动能缓解压力”，下列哪条证据最可信？",["一项持续三个月、有对照组的追踪调查结果","我跑完步心情很好","有人说运动没用","健身房人很多"],0,"有对照、有周期的调查比个人感受更有证据效力。"),
        q("middle-reading-20","reading",.middle,"reading.evidence",.developing,"概括新闻“社区开设老年人智能手机课堂”的核心信息，最准确的是？",["社区开课帮助老年人学习使用智能手机","老年人不会用手机","智能手机功能很多","社区活动很丰富"],0,"概括保留主体、事件和目的，删去无关信息。"),
        q("middle-reading-21","reading",.middle,"reading.evidence",.challenge,"文中两次写到“那把旧藤椅”，推断其作用需要？",["联系两处语境，看它与人物情感、情节推进的关系","只数它出现的次数","查藤椅的市场价格","直接忽略它"],0,"物象作用要回到具体语境，比较两次出现的异同。"),
        q("middle-reading-22","reading",.middle,"reading.structure",.developing,"文章用“信”作为线索贯穿全文，好处是？",["把分散的回忆串联起来，使情感表达集中而自然","显得很有文化","减少文章字数","让读者猜不到结尾"],0,"线索物把材料组织成整体，情感有了落点。"),
        q("middle-reading-23","reading",.middle,"reading.structure",.challenge,"结尾一段重新写到开头的“雨声”，这种写法叫？",["首尾呼应，使结构完整、情感回味","画蛇添足","重复啰嗦","偏离主题"],0,"结尾回扣开头的意象，结构闭合、余韵更长。"),
        q("middle-reading-24","reading",.middle,"reading.language",.developing,"赏析“时间从指缝间悄悄溜走”中“溜”字，最恰当的是？",["拟人化写出时间不知不觉流逝，暗含惋惜","说明时间很会逃跑","表示作者正在看表","与时间的快慢无关"],0,"“溜”赋予时间人的动作，化抽象为可感。"),
        q("middle-reading-25","reading",.middle,"reading.language",.challenge,"“他的沉默像一堵墙。”这个比喻的表达效果是？",["把无形的隔阂写得可感，表现关系的疏离","说明墙很厚","表示他不爱说话","夸他家的墙结实"],0,"以墙喻沉默，把心理距离转化为具体形象。"),
        q("middle-reading-26","reading",.middle,"reading.inquiry",.developing,"对“中学生是否应该带手机进校园”，最符合探究要求的回答是？",["观点明确，并分别回应支持与反对的理由","坚决支持，不需要理由","列举手机的所有功能","把题目抄写一遍"],0,"探究题要有立场、有论据，并回应反面观点。"),
        // 小学 · 文言文（2）
        q("primary-classical-07","classical",.primary,"classical.summary",.foundation,"《司马光砸缸》中司马光最可贵的表现是？",["同伴落水时能冷静想办法救人","力气很大","喜欢玩水","跑得最快"],0,"危急时刻沉着应对、机智救人，是故事的核心。"),
        q("primary-classical-08","classical",.primary,"classical.summary",.foundation,"《守株待兔》讽刺的是？",["心存侥幸、不主动努力的人","勤劳耕种的农夫","跑得太快的兔子","田里的树桩太硬"],0,"把偶然的收获当成必然，放弃劳动，是寓言的寓意。"),
        // 初中 · 文言文（6）
        q("middle-classical-17","classical",.middle,"classical.function",.developing,"“而”在“学而不思则罔”中的作用是？",["表转折，相当于“却”","表并列，相当于“和”","表承接，相当于“就”","表修饰，可不译"],0,"学习与思考在此处是对举中的转折关系。"),
        q("middle-classical-18","classical",.middle,"classical.function",.challenge,"下列句中“之”用作主谓之间、取消句子独立性的是？",["予独爱莲之出淤泥而不染","水陆草木之花","花之君子者也","何陋之有"],0,"“莲之出淤泥而不染”中“之”连接主谓，不译。"),
        q("middle-classical-19","classical",.middle,"classical.sentence",.developing,"“甚矣，汝之不惠”属于哪种句式？",["主谓倒装，强调“不惠”的程度","判断句","被动句","省略句"],0,"谓语“甚矣”前置，正常语序为“汝之不惠甚矣”。"),
        q("middle-classical-20","classical",.middle,"classical.translation",.developing,"翻译“苔痕上阶绿，草色入帘青”最准确的是？",["苔痕蔓延上台阶，使台阶都绿了；草色映入竹帘，使帘内也显得青葱","台阶上长着青苔，帘子里有草","苔藓染绿了台阶，青草爬进了帘子","台阶很绿，帘子很青"],0,"“上”“入”用作动词，要译出苔痕草色的动感与生机。"),
        q("middle-classical-21","classical",.middle,"classical.appreciation",.developing,"《陋室铭》结尾引用孔子“何陋之有”，作用是？",["以圣人之言作结，强化“德馨则室不陋”的主旨","说明孔子住过陋室","凑足文章字数","与上文没有关联"],0,"引用作结，呼应开头“惟吾德馨”，收束有力。"),
        q("middle-classical-22","classical",.middle,"classical.appreciation",.challenge,"《岳阳楼记》写迁客骚人“以物喜，以己悲”，是为了？",["反衬古仁人“不以物喜，不以己悲”的旷达胸襟","批评游客情绪多变","描写洞庭湖的天气","说明景色太美"],0,"两种人生态度形成对比，突出作者推崇的境界。")
    ]

    // MARK: - 批次 2：古诗词 + 作文（24）

    private static let batch2PoetryAndWriting: [ChinQuestion] = [
        // 小学 · 古诗词（6）
        q("primary-poetry-11","poetry",.primary,"poetry.imagery",.foundation,"“两个黄鹂鸣翠柳，一行白鹭上青天”中出现的色彩词是？",["黄、翠、白、青","红、绿、蓝、紫","黑、白、灰、棕","金、银、橙、粉"],0,"黄鹂、翠柳、白鹭、青天，四种色彩构成明快的春景。"),
        q("primary-poetry-12","poetry",.primary,"poetry.imagery",.developing,"“月落乌啼霜满天，江枫渔火对愁眠”描绘了怎样的画面？",["秋夜江边凄清的画面","春日郊游的画面","夏日海边的画面","冬日雪山的画面"],0,"月落、乌啼、霜天、渔火共同营造秋夜的凄清。"),
        q("primary-poetry-13","poetry",.primary,"poetry.word",.developing,"“爆竹声中一岁除”中“除”的意思是？",["逝去、过去","除去杂草","除了","除法"],0,"“一岁除”指一年在爆竹声中过去。"),
        q("primary-poetry-14","poetry",.primary,"poetry.word",.developing,"“疑是地上霜”中“疑”字写出诗人怎样的心理？",["恍惚中把月光当作秋霜，衬出夜深人静时的错觉与乡思","怀疑地上有水","害怕霜冻","不确定是否天亮"],0,"一个“疑”字写出月夜似真似幻的感受。"),
        q("primary-poetry-15","poetry",.primary,"poetry.technique",.foundation,"“飞流直下三千尺，疑是银河落九天”运用的手法是？",["夸张和比喻，写出瀑布的雄伟气势","拟人，写瀑布在跳舞","排比，写很多条瀑布","对比，写山高水低"],0,"“三千尺”是夸张，“银河落九天”是比喻。"),
        q("primary-poetry-16","poetry",.primary,"poetry.technique",.developing,"“荷尽已无擎雨盖，菊残犹有傲霜枝”运用了什么手法？",["对比，以荷尽衬托菊枝傲霜的品格","夸张，写荷叶很大","拟人，写菊花说话","用典，写古人赏菊"],0,"荷败与菊残对比，突出凌霜不屈的气节。"),
        // 初中 · 古诗词（4）
        q("middle-poetry-13","poetry",.middle,"poetry.imagery",.developing,"“鸡声茅店月，人迹板桥霜”纯用名词组合，效果是？",["意象叠加出清冷的早行图，留白含蓄","说明作者忘记写动词","描写集市的热闹","表现夜晚的宁静"],0,"六个意象直接组合，画面自足而余味悠长。"),
        q("middle-poetry-14","poetry",.middle,"poetry.word",.challenge,"“云破月来花弄影”中“弄”字的妙处是？",["拟人写花在月下摇曳弄姿，画面灵动","花在玩弄自己的影子","说明当晚风很大","表示月亮很亮"],0,"“弄”赋予花人的情态，动静相生。"),
        q("middle-poetry-15","poetry",.middle,"poetry.word",.developing,"“羌笛何须怨杨柳，春风不度玉门关”中“怨”字表达？",["戍边将士的乡愁与无奈，含蓄深沉","对笛子的不满","对春天的期待","对杨柳的喜爱"],0,"借笛声之“怨”写人之怨，含蓄写边愁。"),
        q("middle-poetry-16","poetry",.middle,"poetry.emotion",.developing,"“我寄愁心与明月，随君直到夜郎西”表达的情感是？",["对友人被贬的牵挂与同情","赏月时的闲适","对明月的赞美","旅途中的兴奋"],0,"把愁心托付明月，表现对友人的深切挂念。"),
        // 小学 · 作文（5）
        q("primary-writing-15","writing",.primary,"writing.topic",.foundation,"题目《难忘的一天》，下列材料最不切题的是？",["介绍一年四季的天气变化","运动会上班级接力反败为胜","第一次独自坐公交车","生日那天收到意外的道歉"],0,"“一天”要求聚焦具体事件，四季天气与题意无关。"),
        q("primary-writing-16","writing",.primary,"writing.topic",.developing,"命题作文《那一刻，我长大了》，“那一刻”提醒我们要？",["聚焦一个具体瞬间写清变化，而不是流水账写一整天","写很多个时刻","写未来的梦想","写别人的成长"],0,"审清题眼，“那一刻”限定了写作的聚焦点。"),
        q("primary-writing-17","writing",.primary,"writing.detail",.developing,"写“奶奶的手”，最能表现勤劳的细节是？",["手上布满老茧，指关节粗大，还在灯下为我缝扣子","奶奶的手很白","奶奶戴着手套","奶奶会使用手机"],0,"老茧、粗大的关节和缝补的动作是勤劳的直接证据。"),
        q("primary-writing-18","writing",.primary,"writing.application",.foundation,"请假条中必须写清楚的是？",["请假对象、事由、时间和署名","自己的考试成绩","当天的天气预报","班级座位表"],0,"应用文要素齐全，对方才能快速处理。"),
        q("primary-writing-19","writing",.primary,"writing.application",.developing,"写通知“周五下午三点到操场集合”，最不能缺少的信息是？",["时间、地点、事件","通知人的爱好","校园的历史","通知人的心情"],0,"通知的核心是让人知道何时、何地、做什么。"),
        // 初中 · 作文（9）
        q("middle-writing-11","writing",.middle,"writing.topic",.challenge,"材料作文给出“竹子用四年只长3厘米，第五年每天长30厘米”，最佳立意是？",["厚积薄发，扎根沉淀是快速成长的前提","竹子长得太慢","要多种竹子","第五年比前四年重要"],0,"抓住“四年扎根”与“第五年爆发”的因果，立意才深刻。"),
        q("middle-writing-12","writing",.middle,"writing.topic",.developing,"半命题《我战胜了____》，从立意深刻的角度看填哪个更好？",["怯场（由逃避到直面的心理突破）","对手（比赛赢了别人）","懒觉（周末早起）","作业（写完了作业）"],0,"战胜内心障碍比战胜外部对象更有成长意味。"),
        q("middle-writing-13","writing",.middle,"writing.topic",.developing,"以“桥”为题写作，最能避免平淡的构思是？",["由实到虚，从家乡的桥写到人与人之间的沟通之桥","罗列世界上著名的桥","只说明桥的建造过程","写一次过桥的经历就结束"],0,"实物引出象征意义，文章层次更丰富。"),
        q("middle-writing-14","writing",.middle,"writing.detail",.developing,"要表现“寒冷”，最出色的细节是？",["他呵出的白气在围巾上结了一层薄霜，手指冻得解不开拉链","今天零下十度","风很大，大家都喊冷","他穿着厚羽绒服"],0,"白气结霜、手指僵硬是可感的细节，胜过直接报温度。"),
        q("middle-writing-15","writing",.middle,"writing.detail",.challenge,"写“老师批改作业到深夜”，最能打动人的细节是？",["台灯下她揉了揉眼睛，把滑落的披肩拢好，红笔在本子上停了很久才落下一个字","老师工作很辛苦","老师有很多作业要改","老师晚上不看电视"],0,"揉眼、拢披肩、停顿的红笔让辛苦具体可见。"),
        q("middle-writing-16","writing",.middle,"writing.detail",.developing,"用侧面烘托表现“比赛紧张”，可以写？",["观众席突然安静，有人把加油棒捏得咯吱响","运动员都穿着运动服","比赛规则很复杂","体育馆非常大"],0,"借观众的反应烘托气氛，比直接写紧张更有张力。"),
        q("middle-writing-17","writing",.middle,"writing.structure",.developing,"记叙文中间插叙一段童年往事，作用是？",["补充背景，让人物现在的选择更可信","打乱顺序显得高级","单纯增加字数","与主线情节无关"],0,"插叙服务于人物和主题，不是随意穿插。"),
        q("middle-writing-18","writing",.middle,"writing.structure",.challenge,"议论文主体段最规范的结构是？",["分论点—阐释—例证—分析—小结","把几个例子堆在一起","先抒情后喊口号","想到哪里写到哪里"],0,"五步法让每段论证完整、有说服力。"),
        q("middle-writing-19","writing",.middle,"writing.structure",.developing,"以“那盏灯”为线索组织全文，最适合的安排是？",["开头点灯引出回忆—中间两件事借灯写人—结尾灯灭而情不断","只在第一段提一次灯","每段都写灯的价格","结尾突然换成写蜡烛"],0,"线索物在关键节点反复出现，情感层层加深。")
    ]

    // MARK: - 批次 3：综合性学习（14）

    private static let batch3Integrated: [ChinQuestion] = [
        // 小学 · 综合性学习（8）
        q("primary-integrated-13","integrated",.primary,"integrated.chart",.foundation,"图表显示：一年级每天阅读10分钟，三年级20分钟，五年级30分钟。可以得出的结论是？",["随着年级升高，每天阅读时间逐渐增加","一年级学生不爱读书","五年级成绩最好","阅读时间与年级无关"],0,"图表只呈现阅读时间随年级增长的趋势，不作额外推断。"),
        q("primary-integrated-14","integrated",.primary,"integrated.chart",.developing,"调查“喜欢的运动”：跑步占40%、跳绳30%、球类30%。下列说法错误的是？",["所有人都喜欢跑步","喜欢跑步的人最多","跳绳和球类一样多","球类占三成"],0,"40%只是一部分，不能推出“所有人”。"),
        q("primary-integrated-15","integrated",.primary,"integrated.chart",.developing,"借阅统计图中漫画类最高、科普类最低。给图书馆的建议最合理的是？",["适当增加科普类图书的推荐和数量","不再购买漫画书","只买科普书","取消借阅活动"],0,"建议要针对数据反映的不均衡，且可执行。"),
        q("primary-integrated-16","integrated",.primary,"integrated.oral",.developing,"同学借了你的书一直没还，最得体的提醒是？",["“那本书你看完了吗？我这周想用它查资料。”","“你怎么还不还书！”","“算了，送你了。”","“再不还你就是品德有问题。”"],0,"既说明自己的需要，又给对方台阶，语气得体。"),
        q("primary-integrated-17","integrated",.primary,"integrated.oral",.developing,"向陌生人问路，最礼貌的说法是？",["“您好，请问去图书馆怎么走？谢谢！”","“喂，图书馆在哪？”","“带我去图书馆。”","“你不知道图书馆在哪吧？”"],0,"称呼、请问、道谢是问路的基本礼貌。"),
        q("primary-integrated-18","integrated",.primary,"integrated.news",.foundation,"把“我校合唱团在市比赛中获得一等奖”写成新闻标题，最合适的是？",["我校合唱团荣获市比赛一等奖","天大的好消息","大家都来听歌","合唱团的日常"],0,"标题准确概括人物、事件和结果，语言简洁。"),
        q("primary-integrated-19","integrated",.primary,"integrated.language",.developing,"“秋天的校园是一个美丽的季节。”这句病句应改为？",["校园的秋天是一个美丽的季节。","秋天是校园的一个美丽季节。","校园的秋天是一个很美丽。","秋天的校园是美丽季节的很。"],0,"主宾搭配不当，“秋天”才是“季节”，调整语序。"),
        q("primary-integrated-20","integrated",.primary,"integrated.language",.foundation,"“我爱读书，也爱运动。”句中逗号的作用是？",["分隔两个并列的分句","表示强烈的感叹","用在句子末尾","代替问号"],0,"并列分句之间用逗号停顿。"),
        // 初中 · 综合性学习（6）
        q("middle-integrated-07","integrated",.middle,"integrated.chart",.challenge,"折线图显示某班近视率从七年级的30%上升到九年级的55%，最合理的推断是？",["三年间近视率明显上升，需要关注用眼习惯","九年级学生都不爱运动","近视率上升与学习无关","七年级学生视力都很好"],0,"只据趋势提出合理关切，不夸大原因。"),
        q("middle-integrated-08","integrated",.middle,"integrated.chart",.developing,"对比数据：城市学生日均课外阅读52分钟，农村学生31分钟。最负责任的结论是？",["数据显示城乡学生课外阅读时间存在差距，具体原因需进一步调查","农村学生不爱读书","城市学生更聪明","应该取消课外阅读"],0,"呈现差异但不妄断原因，是数据结论的边界。"),
        q("middle-integrated-09","integrated",.middle,"integrated.chart",.developing,"问卷“你完成作业的方式”：独立完成60%、参考同学30%、网上抄答案10%。给班级的建议是？",["肯定独立完成的主流，同时针对抄答案现象加强诚信教育","作业太多应立即取消","参考同学就是作弊","10%的比例可以忽略不管"],0,"既肯定主流，也针对问题给出可执行建议。"),
        q("middle-integrated-10","integrated",.middle,"integrated.slogan",.challenge,"为“保护方言”拟宣传语，最恰当的是？",["留住乡音，记住乡愁","方言已经过时","请只说普通话","方言是交流障碍"],0,"短句点明方言的情感价值，简洁有号召力。"),
        q("middle-integrated-11","integrated",.middle,"integrated.language",.challenge,"“这样的‘聪明人’还是少一点好。”句中引号的作用是？",["表示反语讽刺","表示直接引用","表示着重强调","表示特定称谓"],0,"“聪明人”实指不聪明的人，引号表反语。"),
        q("middle-integrated-12","integrated",.middle,"integrated.language",.developing,"“造纸术是我国古代的四大发明。”这句病句应改为？",["造纸术是我国古代的四大发明之一。","造纸术是我国古代四大发明。","我国古代的四大发明是造纸术。","造纸术是我国的古代四大发明之一。"],0,"一项发明不能等于“四大发明”，需补“之一”。")
    ]

    // MARK: - 批次 4：现代文阅读 + 文言文（48）

    private static let batch4ReadingAndClassical: [ChinQuestion] = [
        // 小学 · 现代文阅读（12）
        q("primary-reading-30","reading",.primary,"reading.character",.foundation,"“老师弯下腰，把撒了一地的作业本一本本捡起来，码整齐。”这个细节表现老师？",["耐心细致、做事认真","作业本太轻","地上很干净","老师喜欢弯腰"],0,"弯腰捡拾、码整齐的动作体现耐心与认真。"),
        q("primary-reading-31","reading",.primary,"reading.character",.developing,"“他嘴上说着‘才不冷’，却悄悄把外套披在了睡着的小弟弟身上。”从中可以看出他？",["嘴硬心软、爱护弟弟","非常怕冷","不喜欢那件外套","想让弟弟感冒"],0,"语言与行动的反差，突出内心的关爱。"),
        q("primary-reading-32","reading",.primary,"reading.evidence",.foundation,"“小刺猬背上扎满了野果，摇摇晃晃走进洞里。”从这句话可以知道？",["小刺猬用刺运回了食物","小刺猬在散步","洞里有别的动物","野果是自己掉上去的"],0,"扎满野果、走进洞里是运食物回家的直接信息。"),
        q("primary-reading-33","reading",.primary,"reading.evidence",.developing,"要说明“今年的收成比去年好”，下列哪条证据最有力？",["粮仓装满了，还新搭了一个棚子存放粮食","今年的雨水很多","田里种了两种庄稼","农具都是新买的"],0,"粮食多到需要新增存放处，直接证明收成增加。"),
        q("primary-reading-34","reading",.primary,"reading.structure",.foundation,"文章先总写“校园真美”，再分别写花坛、操场和教学楼。这样的结构是？",["先总后分","先分后总","倒叙","没有顺序"],0,"开头总起，后文分项展开，是总分结构。"),
        q("primary-reading-35","reading",.primary,"reading.structure",.developing,"文中“从那以后，我再也不敢浪费粮食了”这句话在结构上的作用是？",["总结上文并点明中心","引出下一个新故事","交代天气情况","与上文没有关系"],0,"“从那以后”收束前面的叙事，点出行为的改变。"),
        q("primary-reading-36","reading",.primary,"reading.title",.developing,"标题《最后一课》中“最后”带给读者的感受是？",["郑重、不舍，暗示特殊的告别","轻松、愉快","平常、随意","紧张、害怕"],0,"“最后”意味着结束与告别，奠定惜别的情感基调。"),
        q("primary-reading-37","reading",.primary,"reading.environment",.developing,"“乌云压得很低，连村口的老槐树都一动不动。”这处环境描写的作用是？",["渲染暴雨来临前的沉闷气氛","介绍村口有一棵树","说明今天没有风","描写傍晚的景色"],0,"低垂的乌云和静止的树共同营造压抑的临雨氛围。"),
        q("primary-reading-38","reading",.primary,"reading.language",.foundation,"“高粱涨红了脸，稻子笑弯了腰”运用的修辞手法是？",["拟人","比喻","排比","设问"],0,"“涨红了脸”“笑弯了腰”把庄稼当作人来写。"),
        q("primary-reading-39","reading",.primary,"reading.expository",.developing,"“蜂鸟是世界上最小的鸟，体长只有几厘米，和一枚硬币差不多大。”运用的说明方法是？",["列数字和作比较","打比方和拟人","举例子和引用","排比和对比"],0,"“几厘米”是列数字，“和硬币差不多”是作比较。"),
        q("primary-reading-40","reading",.primary,"reading.inquiry",.developing,"读完《龟兔赛跑》，联系学习生活，最合理的启发是？",["有优势也不能骄傲松懈，坚持才能到达终点","兔子跑得比乌龟快","睡觉能补充体力","比赛一定要去现场看"],0,"兔子因骄傲懈怠落败，乌龟靠坚持获胜，寓意在坚持与不松懈。"),
        q("primary-reading-41","reading",.primary,"reading.strategy",.developing,"读完一个段落，用自己的话说一说“这段讲了什么”，这种做法是？",["用自己的话检验是否真正读懂","浪费时间","代替朗读","应付检查"],0,"复述是检验理解的有效策略，说不清说明没读懂。"),
        // 初中 · 现代文阅读（12）
        q("middle-reading-27","reading",.middle,"reading.character",.developing,"“她把号码布别好，深吸一口气，冲队友笑了笑：‘看我的。’”这组动作和语言表现她？",["自信、敢于承担","紧张得不知所措","想退出比赛","故意炫耀"],0,"深呼吸后的自我激励与主动请战，体现自信与担当。"),
        q("middle-reading-28","reading",.middle,"reading.character",.challenge,"文中写老人“捡废品攒下的钱用红布包了三层，捐款时却一分没留”，这一细节最深刻地表现老人？",["倾其所有的善良与赤诚","不擅长理财","喜欢红色的布","捐款是一时冲动"],0,"攒钱之难与捐款之干脆形成反差，凸显无私。"),
        q("middle-reading-29","reading",.middle,"reading.evidence",.developing,"论证“坚持晨读能提升语感”，下列哪条证据最有说服力？",["一个学期内坚持晨读的学生，朗读测试平均得分提高明显","晨读的声音很响亮","有些学生不喜欢早起","朗读材料是课本里的"],0,"有时间跨度、有结果对比的数据最能支撑结论。"),
        q("middle-reading-30","reading",.middle,"reading.evidence",.challenge,"文中“那封信他一直没拆，却一直放在贴身的口袋里”，理解这个细节需要？",["联系人物的经历，体会“不拆”与“贴身”之间的矛盾情感","数信件出现的次数","查邮票的年代","直接略过这个细节"],0,"行为中的矛盾往往承载复杂情感，需结合语境体会。"),
        q("middle-reading-31","reading",.middle,"reading.structure",.developing,"文章按“种下树苗—照顾小树—树下乘凉”展开，这样安排的好处是？",["以树的成长暗合人的成长，层层推进","为了让文章更长","因为作者喜欢树","可以随意调换顺序"],0,"明线写树、暗线写人，双线并行使结构严谨。"),
        q("middle-reading-32","reading",.middle,"reading.structure",.challenge,"开头写“那台旧缝纫机早就不能用了”，结尾写“我忽然明白它一直在缝补着什么”。这种安排的作用是？",["首尾呼应，使物象的含义在结尾升华","前后矛盾，是写作失误","开头写错了，结尾纠正","与主旨无关"],0,"开头设悬、结尾点题，物象从实物升华为情感象征。"),
        q("middle-reading-33","reading",.middle,"reading.title",.developing,"标题《回家吃饭》表面写吃饭，深层含义最可能是？",["对亲情团聚和朴素家庭温暖的呼唤","教人做饭","批评在外吃饭","介绍一日三餐"],0,"日常小事作标题，往往寄托对亲情与归属感的深层表达。"),
        q("middle-reading-34","reading",.middle,"reading.language",.developing,"赏析“月光把小路洗得发白”中“洗”字，最恰当的是？",["化视觉为可触的动作，写出月色的皎洁与夜晚的宁静","说明小路很脏","表示下过雨","与月亮无关"],0,"“洗”字以动写静，把月光洒落的过程写得可感。"),
        q("middle-reading-35","reading",.middle,"reading.language",.challenge,"“他的话像一颗石子，投进了我平静的心湖。”这个比喻的表达效果是？",["把心理波动写得具体可感，表现话语带来的触动","说明他喜欢扔石子","表示心湖里真的有石头","夸他会游泳"],0,"以石子入湖喻话语入心，化抽象的心理变化为形象画面。"),
        q("middle-reading-36","reading",.middle,"reading.expository",.developing,"说明文先解释“什么是湿地”，再列举湿地的生态功能，最后呼吁保护。说明思路是？",["从概念到作用再到倡议，层层递进","先抒情后说明","按空间位置介绍","想到哪写到哪"],0,"由是什么、为什么到怎么办，符合认知逻辑。"),
        q("middle-reading-37","reading",.middle,"reading.argumentative",.developing,"议论文引用“少年易老学难成，一寸光阴不可轻”作为论据，属于？",["道理论证，借诗句增强说服力","举例论证","对比论证","比喻论证"],0,"引用名言诗句说理，是道理论证（引证法）。"),
        q("middle-reading-38","reading",.middle,"reading.inquiry",.challenge,"有人认为“电子书终将完全取代纸质书”，结合文本反驳最有力的是？",["承认电子书便捷，但指出纸质书在深度阅读和收藏体验上不可替代","电子书太贵","纸质书比较重","我身边没人用电子书"],0,"先承认对方合理处，再用文本证据指出其局限，反驳更有力。"),
        // 小学 · 文言文（12）
        q("primary-classical-09","classical",.primary,"classical.word",.foundation,"“三人行，必有我师焉”中“焉”的意思是？",["在其中","怎么","语气词，不译","疑问代词，哪里"],0,"‘焉’是兼词，相当于‘于之’，即在其中。"),
        q("primary-classical-10","classical",.primary,"classical.word",.foundation,"“敏而好学，不耻下问”中“敏”的意思是？",["聪敏","敏捷","敏感","勤勉"],0,"‘敏而好学’指天资聪敏又喜爱学习。"),
        q("primary-classical-11","classical",.primary,"classical.word",.developing,"“知之为知之，不知为不知，是知也”中最后一个“知”的意思是？",["同“智”，智慧","知道","知识","了解"],0,"末句的‘知’通‘智’，意为这才是智慧。"),
        q("primary-classical-12","classical",.primary,"classical.word",.foundation,"“群儿戏于庭”中“戏”的意思是？",["玩耍、游戏","唱戏","戏弄","戏剧"],0,"句意为一群孩子在庭院里玩耍。"),
        q("primary-classical-13","classical",.primary,"classical.word",.developing,"“光持石击瓮破之”中“持”的意思是？",["拿、握","坚持","保持","支持"],0,"‘持石’即拿起石头。"),
        q("primary-classical-14","classical",.primary,"classical.word",.developing,"“因释其耒而守株”中“释”的意思是？",["放下","解释","释放","消除"],0,"句意为于是放下农具守在树桩旁。"),
        q("primary-classical-15","classical",.primary,"classical.summary",.foundation,"《王戎不取道旁李》中，王戎判断李子是苦的依据是？",["树长在路边却果实满枝，说明没人摘","他尝过这棵树的李子","他看到别人摇头","李子长得不好看"],0,"道旁李树多子，反推无人采摘，可见味苦。"),
        q("primary-classical-16","classical",.primary,"classical.summary",.foundation,"《囊萤夜读》中车胤用萤火虫照明读书，表现他？",["家贫仍勤奋好学","喜欢捉虫子","怕黑","喜欢晚上活动"],0,"以萤代灯，体现贫困条件下坚持学习的精神。"),
        q("primary-classical-17","classical",.primary,"classical.summary",.developing,"《铁杵成针》中老妇人“欲作针”的回答让李白明白了？",["只要功夫深，铁杵磨成针","针很容易做","铁杵不值钱","应该买一根针"],0,"故事说明持之以恒、终能成功的道理。"),
        q("primary-classical-18","classical",.primary,"classical.summary",.foundation,"《精卫填海》中精卫日复一日衔木石填海，表现的精神是？",["意志坚定、不畏艰难","力气很大","喜欢大海","与人为善"],0,"明知难为而持续为之，体现坚韧不屈的意志。"),
        q("primary-classical-19","classical",.primary,"classical.summary",.developing,"《自相矛盾》中楚人被人问倒，是因为？",["他说的话前后抵触，不能自圆其说","他的矛不够锋利","他的盾不够坚固","围观的人故意为难他"],0,"“无不陷之矛”与“莫能陷之盾”不能同时成立。"),
        q("primary-classical-20","classical",.primary,"classical.summary",.developing,"《杨氏之子》中“未闻孔雀是夫子家禽”妙在？",["顺着对方的姓氏思路巧妙回应，既礼貌又机智","声音很大","答非所问","背诵了一段古文"],0,"由“孔”姓联想到“孔雀”，以子之矛攻子之盾，机敏得体。"),
        // 初中 · 文言文（12）
        q("middle-classical-23","classical",.middle,"classical.word",.foundation,"“学而时习之”中“时”的意思是？",["按时","时间","时常","时代"],0,"‘时’在这里是‘按时’，按时温习。"),
        q("middle-classical-24","classical",.middle,"classical.word",.developing,"“其一犬坐于前”中“犬”的用法和意思是？",["名词作状语，像狗一样","名词作动词，养犬","形容词，凶猛的","代词，它的"],0,"‘犬’修饰‘坐’，表示坐的姿态像狗一样。"),
        q("middle-classical-25","classical",.middle,"classical.word",.challenge,"“富贵不能淫，贫贱不能移”中“移”的意思是？",["使……动摇、改变","移动","迁移","交换"],0,"‘移’为使动用法，意为使他的志向动摇。"),
        q("middle-classical-26","classical",.middle,"classical.function",.developing,"“人不知而不愠”中“而”的作用是？",["表转折，却","表承接，就","表并列，并且","表修饰，着"],0,"不了解我却不恼怒，前后是转折关系。"),
        q("middle-classical-27","classical",.middle,"classical.function",.challenge,"下列句中“其”表示“那、那个”的一项是？",["其一犬坐于前","吾日三省吾身","择其善者而从之","人不堪其忧"],0,"‘其一犬坐于前’的‘其’意为‘其中的（那）’，作指示意味的代词；其余为‘自己/他们的/那种’。"),
        q("middle-classical-28","classical",.middle,"classical.sentence",.developing,"“温故而知新，可以为师矣”中“可以”的理解正确的是？",["可以凭借（这一点）","表示允许","表示可能","与现代汉语相同"],0,"古义为‘可以凭借’，是古今异义词。"),
        q("middle-classical-29","classical",.middle,"classical.sentence",.challenge,"“牡丹之爱，宜乎众矣”属于哪种句式？",["主谓倒装，强调“众”","判断句","被动句","宾语前置"],0,"谓语‘宜乎’前置，突出喜爱牡丹的人当然很多。"),
        q("middle-classical-30","classical",.middle,"classical.translation",.developing,"翻译“非淡泊无以明志，非宁静无以致远”最准确的是？",["不能内心恬淡就无法明确志向，不能宁静专一就无法达到远大目标","不淡泊的人没有志向","不安静就走不远","淡泊的人志向都很小"],0,"‘明’为使动用法，‘致远’为达到远大目标。"),
        q("middle-classical-31","classical",.middle,"classical.translation",.challenge,"翻译“予独爱莲之出淤泥而不染，濯清涟而不妖”最准确的是？",["我唯独喜爱莲从淤泥里长出来却不沾染污秽，经过清水洗涤却不显得妖艳","我只喜欢莲花很干净","莲花在淤泥里也会开花","莲花洗过以后更漂亮"],0,"‘染’为沾染污秽，‘妖’为艳丽，要译出转折意味。"),
        q("middle-classical-32","classical",.middle,"classical.summary",.developing,"《卖油翁》中“惟手熟尔”揭示的道理是？",["熟能生巧，技艺来自反复练习","倒油很简单","卖油翁很傲慢","射箭不需要练习"],0,"以倒油喻一切技艺，强调练习造就精湛。"),
        q("middle-classical-33","classical",.middle,"classical.appreciation",.developing,"《爱莲说》写菊花和牡丹，是为了？",["以菊和牡丹衬托莲的君子品格","介绍三种花","说明作者只喜欢莲","凑足文章篇幅"],0,"正衬与反衬并用，突出莲‘花之君子’的形象。"),
        q("middle-classical-34","classical",.middle,"classical.appreciation",.challenge,"《记承天寺夜游》中“闲人”一词包含的情感最准确的是？",["既有贬谪的落寞，又有自我排遣的旷达","完全悠闲自在","对朝廷的愤怒","对朋友的嘲笑"],0,"‘闲’字双关，微妙地融合了失落与超脱两种情绪。")
    ]

    // MARK: - 批次 5：古诗词 + 作文（48）

    private static let batch5PoetryAndWriting: [ChinQuestion] = [
        // 小学 · 古诗词（12）
        q("primary-poetry-17","poetry",.primary,"poetry.imagery",.foundation,"“接天莲叶无穷碧，映日荷花别样红”描写的季节是？",["夏季","春季","秋季","冬季"],0,"莲叶、荷花是盛夏的典型景物。"),
        q("primary-poetry-18","poetry",.primary,"poetry.imagery",.foundation,"“千山鸟飞绝，万径人踪灭”描绘的画面是？",["大雪后山野的空寂","春天山林的热闹","秋天的丰收景象","清晨的鸟鸣"],0,"‘绝’‘灭’写出雪后无鸟无人的空旷寂静。"),
        q("primary-poetry-19","poetry",.primary,"poetry.imagery",.developing,"“泥融飞燕子，沙暖睡鸳鸯”一动一静，写出了春日怎样的特点？",["温暖、生机与安宁","寒冷、萧瑟","风雨交加","黑夜漫长"],0,"燕子飞舞是动，鸳鸯安睡是静，合写春日温暖和乐。"),
        q("primary-poetry-20","poetry",.primary,"poetry.word",.developing,"“春风又绿江南岸”中“绿”字历来为人称道，是因为？",["把春风写得有形有色，写出江南由枯转绿的过程","绿色是诗人最喜欢的颜色","‘绿’字笔画少好写","‘绿’和‘岸’押韵"],0,"形容词作动词用，一字活化整个春回大地的画面。"),
        q("primary-poetry-21","poetry",.primary,"poetry.word",.developing,"“红杏枝头春意闹”中“闹”字的妙处是？",["用听觉感受写视觉繁盛，写出杏花怒放的热闹生机","杏花会发出声音","诗人觉得杏树很吵","‘闹’说明蜜蜂很多"],0,"通感手法，一个‘闹’字使静态的花有了动态与声响。"),
        q("primary-poetry-22","poetry",.primary,"poetry.word",.developing,"“轻舟已过万重山”中“轻”字写出了？",["行船的轻快和诗人遇赦东归的畅快心情","船没有装货","船是用轻木做的","江水很浅"],0,"‘轻’字既是船行之快，更是心情之轻快。"),
        q("primary-poetry-23","poetry",.primary,"poetry.technique",.foundation,"“桃花潭水深千尺，不及汪伦送我情”运用了什么手法？",["夸张和对比，用潭水之深反衬情谊更深","比喻，把友情比作潭水","拟人，潭水有情","排比，增强气势"],0,"以‘深千尺’的夸张对比‘不及’，突出情谊之深。"),
        q("primary-poetry-24","poetry",.primary,"poetry.technique",.developing,"“欲穷千里目，更上一层楼”在写法上的特点是？",["即景说理，借登楼写出站得高看得远的道理","纯粹写景，没有含义","描写楼梯很高","批评看不清远处的人"],0,"后两句由眼前景引出人生哲理，景与理自然融合。"),
        q("primary-poetry-25","poetry",.primary,"poetry.technique",.developing,"“独在异乡为异客，每逢佳节倍思亲”中两个‘异’字和‘倍’字的作用是？",["层层加重，突出孤独处境中思亲之情的浓烈","说明诗人在外国","表示诗人不喜欢节日","为了凑字数"],0,"‘异乡’‘异客’铺足孤独感，‘倍’字点出节日的加倍思念。"),
        q("primary-poetry-26","poetry",.primary,"poetry.emotion",.foundation,"“举头望明月，低头思故乡”表达的情感是？",["月夜思乡的深挚情感","赏月的快乐","对月亮的好奇","深夜失眠的烦恼"],0,"举头低头之间，由望月自然引出对故乡的思念。"),
        q("primary-poetry-27","poetry",.primary,"poetry.emotion",.developing,"“但使龙城飞将在，不教胡马度阴山”表达了诗人怎样的愿望？",["盼望良将守边、保家卫国","希望去阴山游玩","想成为将军","对战争的赞美"],0,"借对良将的呼唤，表达平息边患、安定边疆的愿望。"),
        q("primary-poetry-28","poetry",.primary,"poetry.emotion",.developing,"“粉骨碎身浑不怕，要留清白在人间”借石灰表达了诗人？",["不怕牺牲、坚守高洁品格的志向","制作石灰的技术","对白色的喜爱","对石头的赞美"],0,"托物言志，以石灰自喻，表明持身清白、无惧磨难的心志。"),
        // 初中 · 古诗词（12）
        q("middle-poetry-17","poetry",.middle,"poetry.imagery",.developing,"“杨花落尽子规啼”一句选取杨花、子规两个意象，作用是？",["点明暮春时令，渲染飘零感伤的离别氛围","描写春天的生机","说明鸟叫声好听","介绍植物知识"],0,"杨花飘尽、杜鹃哀啼，皆为离别烘托伤感氛围。"),
        q("middle-poetry-18","poetry",.middle,"poetry.imagery",.developing,"“马作的卢飞快，弓如霹雳弦惊”描绘的场面是？",["激烈惊险的战斗场面","悠闲的狩猎场面","赛马的娱乐场面","平静的行军场面"],0,"快马惊弓，从视觉听觉写出战场的紧张激烈。"),
        q("middle-poetry-19","poetry",.middle,"poetry.imagery",.challenge,"“夕阳西下，断肠人在天涯”中“夕阳”意象的作用是？",["以暮色烘托游子的孤独与思乡之痛","说明时间很晚","表示天气晴朗","描写晚霞很美"],0,"夕阳西下的苍茫暮色，加深了天涯孤旅的悲凉。"),
        q("middle-poetry-20","poetry",.middle,"poetry.word",.developing,"“大漠孤烟直，长河落日圆”中“直”“圆”二字好在？",["以极简的笔画勾勒边塞景物的形态，画面雄浑开阔","说明烟不弯曲","表示太阳很圆","为了对仗工整"],0,"一‘直’一‘圆’，线条简明而意境阔大，被誉为‘千古壮观’。"),
        q("middle-poetry-21","poetry",.middle,"poetry.word",.challenge,"“山重水复疑无路，柳暗花明又一村”中“疑”字写出了？",["山环水绕中以为无路、忽见村庄的惊喜过程","诗人真的迷了路","诗人不相信有村庄","诗人害怕继续走"],0,"‘疑’字写出行路时的心理变化，与‘又’字呼应成趣。"),
        q("middle-poetry-22","poetry",.middle,"poetry.word",.developing,"“采菊东篱下，悠然见南山”中“见”字比“望”字更好，是因为？",["‘见’是无意中的自然相遇，更能表现心境的闲适自得","‘见’字更通俗","‘望’字写错了","‘见’和‘山’押韵"],0,"无意间抬头见山，物我两忘；若用‘望’则有了刻意之态。"),
        q("middle-poetry-23","poetry",.middle,"poetry.technique",.developing,"“怀旧空吟闻笛赋，到乡翻似烂柯人”运用的手法是？",["用典，借向秀闻笛、王质烂柯表达对故友的怀念和人事沧桑之感","比喻，写笛声优美","夸张，写时间漫长","拟人，写斧头有情"],0,"连用两个典故，一悼亡友，一叹岁月蹉跎。"),
        q("middle-poetry-24","poetry",.middle,"poetry.technique",.developing,"“日月之行，若出其中；星汉灿烂，若出其里”运用的手法是？",["想象和夸张，写大海吞吐日月星辰的宏伟气象","写实，记录天文现象","拟人，大海会说话","排比，增强节奏"],0,"诗人借想象写大海的包容，暗寓自己博大的胸襟。"),
        q("middle-poetry-25","poetry",.middle,"poetry.technique",.challenge,"“春蚕到死丝方尽，蜡炬成灰泪始干”运用的手法是？",["双关和比喻，‘丝’谐音‘思’，写至死不渝的思念","夸张，写春蚕很多","拟人，写蜡烛哭泣","排比，增强语势"],0,"‘丝’与‘思’谐音双关，以春蚕蜡炬喻执着深情。"),
        q("middle-poetry-26","poetry",.middle,"poetry.emotion",.foundation,"“但愿人长久，千里共婵娟”表达的情感是？",["对亲人的美好祝愿与豁达情怀","对月亮的赞美","离别的悲伤绝望","对家乡的思念"],0,"但愿彼此平安长久，即使相隔千里也能共赏明月，旷达而深情。"),
        q("middle-poetry-27","poetry",.middle,"poetry.emotion",.developing,"“了却君王天下事，赢得生前身后名。可怜白发生！”表达的情感是？",["壮志难酬的悲愤","功成名就的喜悦","对衰老的恐惧","归隐的闲适"],0,"梦中的收复壮志与醒来的白发现实形成强烈反差，悲愤深沉。"),
        q("middle-poetry-28","poetry",.middle,"poetry.emotion",.challenge,"“先天下之忧而忧，后天下之乐而乐”表达的胸怀是？",["以天下为己任、忧国忧民的政治抱负","只关心自己的快乐","悲观厌世","及时行乐"],0,"把个人的忧乐置于天下人之后，体现崇高的济世情怀。"),
        // 小学 · 作文（12）
        q("primary-writing-20","writing",.primary,"writing.topic",.foundation,"命题作文《一件令我感动的事》，下列选材最切题的是？",["妈妈深夜冒雨送我去医院","学校有美丽的花坛","我养了一只小猫","暑假去了很多地方"],0,"‘感动’要求选取触动情感的具体事件，深夜送医最能承载。"),
        q("primary-writing-21","writing",.primary,"writing.topic",.developing,"半命题《____，我想对你说》，选哪个对象最容易写出真情实感？",["每天接送我的奶奶","一位古代名人","动画片角色","学校的国旗"],0,"身边熟悉的人有真实相处细节，情感有依托。"),
        q("primary-writing-22","writing",.primary,"writing.topic",.developing,"以“变”为话题，最有新意的构思是？",["写外婆从拒绝智能手机到学会视频通话的变化","写春夏秋冬的变化","写自己长高了","写铅笔变短了"],0,"人物观念与生活的变化有时代感，细节真实可写。"),
        q("primary-writing-23","writing",.primary,"writing.detail",.foundation,"写“爸爸修自行车”，最能表现认真的细节是？",["他眯着眼拧紧每一颗螺丝，又用手转了转车轮才点头","爸爸会修车","工具箱很大","修了很长时间"],0,"拧螺丝、试车轮的连贯动作把‘认真’写成了画面。"),
        q("primary-writing-24","writing",.primary,"writing.detail",.developing,"写“热闹的运动会”，用点面结合最合适的是？",["先写全场沸腾的场面，再聚焦一名冲刺的同学","只写自己班级的座位","只写裁判老师","只写天气晴朗"],0,"‘面’写整体氛围，‘点’写个体特写，场面才有层次。"),
        q("primary-writing-25","writing",.primary,"writing.detail",.developing,"要表现“等待的焦急”，最合适的细节是？",["他一会儿看表，一会儿踮脚往路口望，手里的花被捏得变了形","他等了很久","他心里很着急","时间过得很慢"],0,"看表、踮脚、捏花三组动作，把抽象的焦急外化为可见细节。"),
        q("primary-writing-26","writing",.primary,"writing.structure",.foundation,"写《第一次做饭》，按什么顺序写最清楚？",["事情发展顺序：准备—动手—遇挫—完成—感受","想到什么写什么","先写感受再倒推","只写最后的成果"],0,"按事情发展的先后顺序，过程完整、条理清晰。"),
        q("primary-writing-27","writing",.primary,"writing.structure",.developing,"《我的文具盒》结尾最能呼应开头的是？",["这个旧文具盒装的不只是铅笔，还有妈妈送它时说的那句话。","我的文具盒是蓝色的。","文具都是商店买的。","我又买了一个新文具盒。"],0,"结尾回扣文首的来历并升华情感，结构完整。"),
        q("primary-writing-28","writing",.primary,"writing.language",.foundation,"将“风很大”写具体，最合适的是？",["风把行道树吹得东倒西歪，塑料袋打着旋儿飞上了半空。","风非常非常非常大。","今天刮大风，真大。","风大得无法形容。"],0,"用树、塑料袋的具体状态侧面表现风力，胜过空喊‘大’。"),
        q("primary-writing-29","writing",.primary,"writing.language",.developing,"修改病句“我们全校师生都参加了植树活动，只有生病的小明没来。”，正确的是？",["我们学校几乎全校师生都参加了植树活动。→ 删去矛盾：改为“全校师生基本上都参加了植树活动”","我们全校师生都参加了植树活动，小明也参加了。","只有小明参加了植树活动。","全校师生都没参加植树活动。"],0,"‘都参加’与‘小明没来’自相矛盾，删去绝对化表述。"),
        q("primary-writing-30","writing",.primary,"writing.application",.foundation,"写留言条告诉妈妈自己去图书馆了，必须写清的是？",["去向、事由和留言人","图书馆的历史","书包的颜色","对妈妈的要求"],0,"留言条要让对方一看就明白你去了哪里、做什么。"),
        q("primary-writing-31","writing",.primary,"writing.application",.developing,"班级失物招领启事中，下列哪项写法最合适？",["写清物品特征、拾到地点和认领方式","写出物品购买价格","批评丢东西的同学","写自己的兴趣爱好"],0,"招领启事的核心是让失主确认物品并方便认领。"),
        // 初中 · 作文（12）
        q("middle-writing-20","writing",.middle,"writing.topic",.developing,"命题作文《原来，我也可以》，审题的关键是？",["写出由“以为不行”到“发现可以”的心理转变过程","写别人对我的夸奖","写一次轻松的胜利","写“原来”这个词的意思"],0,"‘原来’暗示认知反转，文章重心应放在转变的契机与过程。"),
        q("middle-writing-21","writing",.middle,"writing.topic",.challenge,"材料“有人抱怨鞋子不好看，直到他看见没有脚的人”，最佳立意是？",["珍惜已有，换个角度看待自己的处境","鞋子的样式不重要","要多帮助别人","不要抱怨生活"],0,"材料核心是视角转换带来的心态改变，立意应落在知足与换位。"),
        q("middle-writing-22","writing",.middle,"writing.topic",.developing,"以“镜头”为题写作，最能写出深度的构思是？",["以三个生活镜头串起对‘平凡中的善意’的发现","介绍照相机的镜头","写一次拍照的经历","罗列电影里的镜头"],0,"用‘镜头’作结构装置，以片段组合表达统一主题。"),
        q("middle-writing-23","writing",.middle,"writing.detail",.developing,"写“寒冬里的温暖”，最动人的细节是？",["卖烤红薯的老人把炉边最暖和的位置让给了躲雨的环卫工","冬天很冷，人很好","老人卖红薯很多年","环卫工早上起得很早"],0,"‘让位置’的具体举动把温暖落到了实处，小切口见大情感。"),
        q("middle-writing-24","writing",.middle,"writing.detail",.challenge,"写“那一刻，我读懂了父亲”，最能承载‘读懂’的细节是？",["看到父亲把我的错题一题题抄在本子上，旁边标着他查字典写下的拼音","父亲每天上班很辛苦","父亲给我买了新书包","父亲不爱说话"],0,"抄错题、标拼音的细节藏着不善言辞的爱，‘读懂’有了依据。"),
        q("middle-writing-25","writing",.middle,"writing.structure",.developing,"以“距离”为题写记叙文，最清晰的结构是？",["由空间距离写到心理距离，最后写距离被一次主动沟通消融","开头结尾都写路程很远","按东、南、西、北四个方向写","只写与朋友的地理距离"],0,"由实入虚再回到行动，层层递进，结构完整。"),
        q("middle-writing-26","writing",.middle,"writing.structure",.challenge,"议论文《谈坚持》最适合的分论点展开方式是？",["坚持需要明确目标—坚持需要抵抗诱惑—坚持需要适时调整方法","坚持很重要—坚持很重要—坚持很重要","爱迪生的事例—居里夫人的事例—无分析","喊口号—讲故事—再喊口号"],0,"三个分论点层层递进、各有侧重，且需例证与分析结合。"),
        q("middle-writing-27","writing",.middle,"writing.application",.foundation,"申请书中不需要出现的内容是？",["对审批人的吹捧和私人馈赠承诺","申请事项","申请理由","申请人署名和日期"],0,"申请书应庄重规范，事项、理由、署名日期齐全即可。"),
        q("middle-writing-28","writing",.middle,"writing.application",.developing,"写毕业活动策划方案，最完整的要素组合是？",["活动目标—流程安排—人员分工—应急预案","主持人姓名—背景音乐—气球颜色","聚餐菜单—合影姿势—服装要求","校长讲话稿全文—座位表—班车路线"],0,"方案要覆盖目标、流程、分工与突发应对，才能落地执行。"),
        q("middle-writing-29","writing",.middle,"writing.argument",.developing,"论点为“慢也是一种智慧”，下列论据最恰当的是？",["达芬奇反复画蛋打基础，终成一代巨匠","有人做事很慢被批评","现代人节奏都很快","乌龟跑得慢"],0,"事例中‘慢’是刻意的基础打磨，能证明慢的价值。"),
        q("middle-writing-30","writing",.middle,"writing.argument",.challenge,"材料“喷泉之所以美丽，是因为它有压力；瀑布之所以壮观，是因为它没有退路”，最佳立意是？",["压力与绝境能激发潜能，成就人生之美","喷泉和瀑布很好看","水往低处流","要修建更多喷泉"],0,"抓住‘压力’‘退路’与‘美丽’‘壮观’的因果关联，立意落在逆境激发潜能。"),
        q("middle-writing-31","writing",.middle,"writing.argument",.developing,"论证“自律者自由”，下列道理论据最合适的是？",["不能制约自己的人，不能称之为自由的人。","生命在于运动。","书籍是人类进步的阶梯。","团结就是力量。"],0,"名言直接揭示自我约束与自由的关系，与论点匹配。")
    ]

    // MARK: - 批次 6：综合性学习（24）

    private static let batch6Integrated: [ChinQuestion] = [
        // 小学 · 综合性学习（12）
        q("primary-integrated-21","integrated",.primary,"integrated.chart",.foundation,"统计图显示：周一到周五班级图书角借阅量逐日上升，周五最高。最合理的解释是？",["临近周末，同学们借书回家阅读","周五的书最好看","图书角只有周五开放","周一大家都忘了带书"],0,"从借阅规律联系周末阅读需求，解释最合乎常理。"),
        q("primary-integrated-22","integrated",.primary,"integrated.chart",.developing,"调查“每天看电视时间”：30分钟以内20人，30-60分钟25人，1小时以上5人。可以得出？",["多数同学每天看电视在一小时以内","所有同学都爱看电视","看一小时以上的占多数","看电视对眼睛没有影响"],0,"20+25=45人处于一小时以内区间，占全班绝大多数。"),
        q("primary-integrated-23","integrated",.primary,"integrated.oral",.foundation,"请老师帮你讲解一道题，最礼貌的说法是？",["“老师，这道题我想了很久还是没弄懂，您能给我讲讲吗？”","“老师，这题我不会，快教我。”","“这题太难了，不学了。”","“老师你过来一下。”"],0,"说明自己的尝试、使用礼貌用语提出请求，最得体。"),
        q("primary-integrated-24","integrated",.primary,"integrated.oral",.developing,"小组讨论时意见不同，最恰当的做法是？",["认真听完对方的理由，再说出自己的想法","大声争论直到对方同意","不理会别人，按自己的做","请老师直接决定"],0,"先倾听后表达，既尊重他人又能推进讨论。"),
        q("primary-integrated-25","integrated",.primary,"integrated.slogan",.foundation,"为“保护眼睛”拟宣传语，最恰当的是？",["让眼睛多一分休息，让世界多一分清晰","眼睛是器官","近视可以戴眼镜","请不要一直看近处"],0,"句式整齐、有行动指向和画面感，适合宣传。"),
        q("primary-integrated-26","integrated",.primary,"integrated.slogan",.developing,"运动会会徽由跑道和燃烧的火焰组成，寓意最合理的是？",["在赛场上奋力拼搏、热情向上","火焰很危险","跑道是红色的","运动会要点火"],0,"跑道象征赛场，火焰象征激情与拼搏精神。"),
        q("primary-integrated-27","integrated",.primary,"integrated.news",.foundation,"给“三年级同学为敬老院表演节目”拟新闻标题，最合适的是？",["童心暖夕阳：三年级学生走进敬老院","敬老院很大","表演节目真好看","三年级的一天"],0,"标题点明人物、事件并传递温情，简洁醒目。"),
        q("primary-integrated-28","integrated",.primary,"integrated.news",.developing,"校园新闻结尾写“这次活动让同学们收获满满”，这种写法叫？",["简要总结意义，收束全文","提出新的疑问","重复导语","罗列数据"],0,"结尾点明活动意义，使报道结构完整。"),
        q("primary-integrated-29","integrated",.primary,"integrated.activity",.foundation,"“走进菜市场”实践活动出发前，最必要的准备是？",["明确观察任务、准备记录工具并约定安全事项","带很多零花钱","背一首关于蔬菜的诗","比赛谁走得快"],0,"有任务、有工具、有安全约定，活动才能有序有效。"),
        q("primary-integrated-30","integrated",.primary,"integrated.activity",.developing,"小组合作完成“家乡特产”手抄报，最合理的分工方式是？",["按资料收集、版面设计、文字撰写、插图分工并互相配合","让组长一个人完成","每人随便画一点","先玩再做，最后赶工"],0,"按任务模块分工、各司其职又协同，效率和质量才有保障。"),
        q("primary-integrated-31","integrated",.primary,"integrated.language",.foundation,"“我们要养成认真检查作业的好习惯。”这句话没有语病，它的主干是？",["我们养成习惯","我们检查作业","养成好习惯","检查作业"],0,"提取主谓宾：我们（主语）养成（谓语）习惯（宾语）。"),
        q("primary-integrated-32","integrated",.primary,"integrated.language",.developing,"“他大约十岁左右，长得很高。”这句病句应改为？",["他十岁左右，长得很高。","他大约十岁左右的，长得很高。","他大约十岁上下左右，长得很高。","他十岁左右大约，长得很高。"],0,"‘大约’与‘左右’语义重复，删去其一。"),
        // 初中 · 综合性学习（12）
        q("middle-integrated-13","integrated",.middle,"integrated.chart",.developing,"数据显示：坚持课前预习的同学，课堂提问正确率为82%；不预习的同学为54%。最稳妥的结论是？",["本次调查中，预习与课堂表现呈正相关，值得提倡","不预习一定学不好","预习是成绩好的唯一原因","54%的同学不该提问"],0,"呈现相关性并给出适度倡导，不夸大为绝对因果。"),
        q("middle-integrated-14","integrated",.middle,"integrated.chart",.challenge,"图表：某市图书馆纸质书借阅量五年间缓慢下降，电子书借阅量快速上升。最合理的推断是？",["阅读载体的使用习惯正在发生变化，图书馆可据此优化服务","纸质书即将消失","人们不再阅读","电子书内容更好"],0,"只从数据趋势推断习惯变化，并落到可行的服务建议上。"),
        q("middle-integrated-15","integrated",.middle,"integrated.chart",.developing,"问卷“你最喜欢的名著阅读方式”：精读批注35%、泛读了解45%、听书了解20%。给阅读活动的建议是？",["尊重多元方式的同时，引导部分同学尝试精读批注","强制所有人精读","取消听书","泛读没有价值"],0,"既尊重数据反映的多样性，又给出建设性引导。"),
        q("middle-integrated-16","integrated",.middle,"integrated.slogan",.developing,"为“书香校园”拟标语，最恰当的是？",["最是书香能致远，腹有诗书气自华","读书使人进步（贴在食堂）","请保持安静！","图书馆藏书十万册"],0,"化用诗句、对仗雅致，契合主题又有文化味。"),
        q("middle-integrated-17","integrated",.middle,"integrated.slogan",.challenge,"上联“清风明月本无价”，下联最恰当的是？",["近水远山皆有情","两个黄鹂鸣翠柳","一寸光阴一寸金","红雨随心翻作浪"],0,"‘近水远山’对‘清风明月’，‘皆有情’对‘本无价’，对仗工整。"),
        q("middle-integrated-18","integrated",.middle,"integrated.slogan",.developing,"徽标主体是打开的书页化作飞鸟，寓意最合理的是？",["阅读带人飞向更广阔的世界","书页很薄","飞鸟喜欢书","图书馆在郊外"],0,"书化飞鸟，形象表达阅读拓展视野、放飞思想。"),
        q("middle-integrated-19","integrated",.middle,"integrated.language",.developing,"“通过这次劳动实践，使同学们体会到了粮食的来之不易。”这句病句应改为？",["这次劳动实践，使同学们体会到了粮食的来之不易。","通过这次劳动实践，同学们使粮食来之不易。","通过这次劳动实践，使粮食来之不易。","通过劳动实践，使同学们体会粮食。"],0,"‘通过……使……’并用导致主语残缺，删去‘通过’。"),
        q("middle-integrated-20","integrated",.middle,"integrated.language",.challenge,"下列句子中标点使用正确的一项是？",["“你到底去不去？”他提高了声音问。","“你到底去不去”？他提高了声音问。","“你到底去不去？”他提高了声音问：","“你到底去不去。”他提高了声音问？"],0,"疑问句问号在引号内，‘问’后接句号。"),
        q("middle-integrated-21","integrated",.middle,"integrated.language",.developing,"“人生的道路虽然漫长，但紧要处常常只有几步。”句中破折号若用在“紧要处——特别是青年时期”，作用是？",["表示解释说明","表示声音延长","表示话题转换","表示说话中断"],0,"破折号后对‘紧要处’作进一步解释。"),
        q("middle-integrated-22","integrated",.middle,"integrated.material",.developing,"材料一：诵读经典能积累语言；材料二：诵读经典能涵养品格。整合两则材料，核心观点是？",["诵读经典兼具语言积累与人格涵养的双重价值","诵读只是为了考试","经典只适合背诵","材料二比材料一重要"],0,"整合要求兼顾两则材料的信息，不遗漏、不偏废。"),
        q("middle-integrated-23","integrated",.middle,"integrated.material",.challenge,"材料一：AI写作工具能快速成文；材料二：过度依赖工具使部分学生写作能力下降。最合理的立场是？",["把工具作为辅助而非替代，坚持自主构思与表达","全面禁止使用工具","用工具代替一切写作","写作课没有存在的必要"],0,"承认工具价值、指出依赖风险、守住能力本位，立场辩证。"),
        q("middle-integrated-24","integrated",.middle,"integrated.material",.developing,"比较两则对同一事件的不同报道，首先要做的是？",["核对双方的基本事实是否一致，再分析立场与措辞差异","直接相信标题更醒目的一方","只看配图","比较两则报道的字数"],0,"事实是底线，先核对事实再分析倾向，才不会被立场带偏。")
    ]

    // MARK: - 批次 7：按权重查缺补漏 · 初中补强（38）

    private static let supplementJunior: [ChinQuestion] = [
        // 文言文 · 实词（6）
        q("sup-j-01","classical",.middle,"classical.word",.developing,"“属予作文以记之”中的“属”意思是？",["嘱托（通“嘱”）","属于","类属","连接"],0,"“属”通“嘱”，意思是嘱托我写篇文章来记述这件事。"),
        q("sup-j-02","classical",.middle,"classical.word",.challenge,"“食之不能尽其材”中的“食”通哪个字、意思是？",["“饲”，喂养","“蚀”，侵蚀","“识”，认识","“适”，适合"],0,"“食”通“饲”，读 sì，意思是喂养。"),
        q("sup-j-03","classical",.middle,"classical.word",.developing,"“率妻子邑人来此绝境”中“绝境”的古义是？",["与世隔绝的地方","没有出路的境地","十分危险的处境","两国的边境"],0,"古义指与外界隔绝的地方，今义才指走投无路的境地。"),
        q("sup-j-04","classical",.middle,"classical.word",.developing,"“小大之狱，虽不能察，必以情”中的“狱”指？",["案件、官司","监狱","打官司的人","刑罚"],0,"文言里“狱”常指案件，不是关押犯人的场所。"),
        q("sup-j-05","classical",.middle,"classical.word",.challenge,"“吾妻之美我者，私我也”中的“私”意思是？",["偏爱","私下","秘密","自私"],0,"“私”在这里作动词，意为偏爱。"),
        q("sup-j-06","classical",.middle,"classical.word",.developing,"“一狼洞其中”的“洞”属于什么用法？",["名词用作动词，打洞","名词作状语","使动用法","意动用法"],0,"“洞”本是名词，后面带了补语，活用为动词，意为打洞。"),
        // 文言文 · 虚词（4）
        q("sup-j-07","classical",.middle,"classical.function",.developing,"“予独爱莲之出淤泥而不染”中的“之”作用是？",["取消句子独立性，不译","结构助词“的”","代词，指莲","动词，去往"],0,"“之”用在主谓之间，取消句子独立性，使全句成为“爱”的宾语。"),
        q("sup-j-08","classical",.middle,"classical.function",.challenge,"“其真无马邪”中的“其”表示什么语气？",["难道，表反问","大概，表推测","他的，表领属","其中的"],0,"与句末“邪”呼应，表反问，相当于“难道”。"),
        q("sup-j-09","classical",.middle,"classical.function",.foundation,"“学而不思则罔”中的“而”表示？",["转折","并列","承接","修饰"],0,"“学”与“不思”意思相对，这里表转折。"),
        q("sup-j-10","classical",.middle,"classical.function",.developing,"“以中有足乐者”中的“以”意思是？",["因为","用","凭借","以便"],0,"“以”表原因，意为因为内心有值得快乐的事。"),
        // 文言文 · 特殊句式（4）
        q("sup-j-11","classical",.middle,"classical.sentence",.developing,"“何陋之有”属于哪种特殊句式？",["宾语前置","定语后置","状语后置","被动句"],0,"“之”是宾语前置的标志，正常语序为“有何陋”。"),
        q("sup-j-12","classical",.middle,"classical.sentence",.challenge,"“马之千里者，一食或尽粟一石”属于哪种句式？",["定语后置","宾语前置","状语后置","被动句"],0,"“千里”是“马”的定语，用“之……者”后置，起强调作用。"),
        q("sup-j-13","classical",.middle,"classical.sentence",.developing,"“帝感其诚”属于哪种句式？",["被动句","判断句","省略句","倒装句"],0,"意思是天帝被他的诚心所感动，是没有标志的意念被动句。"),
        q("sup-j-14","classical",.middle,"classical.sentence",.challenge,"“一鼓作气，再而衰，三而竭”主要省略了什么成分？",["谓语“鼓”","主语","宾语","状语"],0,"应为“再（鼓）而衰，三（鼓）而竭”，承前省略谓语。"),
        // 文言文 · 翻译（4）
        q("sup-j-15","classical",.middle,"classical.translation",.developing,"“不以物喜，不以己悲”应译为？",["不因外物的好坏和自己的得失而或喜或悲","不喜欢外物，也不为自己悲伤","不因为得到物品而高兴","对外物和个人都不关心"],0,"两句互文见义，两个“以”都表原因，翻译时要合起来理解。"),
        q("sup-j-16","classical",.middle,"classical.translation",.challenge,"“陟罚臧否，不宜异同”中的“异同”属于？",["偏义复词，只取“异”义","并列的两个意思","同义词连用","反义词对比"],0,"偏义复词，只取“异”，意为奖罚标准不应有所不同。"),
        q("sup-j-17","classical",.middle,"classical.translation",.developing,"“先帝不以臣卑鄙”中“卑鄙”的古义是？",["身份低微、见识短浅","品德恶劣","行为粗鲁","出身贫寒"],0,"古义不含贬斥，是诸葛亮自谦的说法。"),
        q("sup-j-18","classical",.middle,"classical.translation",.challenge,"翻译“率妻子邑人来此绝境”，最要落实的是？",["妻子儿女、乡人与与世隔绝之地","妻子的家乡","率领军队","危险的处境"],0,"“妻子”是两个词，“绝境”取古义，两处都要译准。"),
        // 文言文 · 写法与主旨（3）
        q("sup-j-19","classical",.middle,"classical.appreciation",.developing,"《岳阳楼记》结句“微斯人，吾谁与归”的作用是？",["表明志向，并慨叹知音难觅","询问回家的路","交代写作时间","补写岳阳楼景色"],0,"用反问收束，既表明心志，又含孤独与期盼之情。"),
        q("sup-j-20","classical",.middle,"classical.appreciation",.developing,"《醉翁亭记》中“醉翁之意不在酒”的“意”指？",["寄情山水、与民同乐","酒量很好","想要喝醉","醉倒在亭子里"],0,"“意”是情趣，落在山水之乐与同民之乐上。"),
        q("sup-j-21","classical",.middle,"classical.appreciation",.challenge,"《陋室铭》主要运用的写法是？",["托物言志","借景抒情","对比论证","直抒胸臆"],0,"借陋室表达高洁傲岸的节操与安贫乐道的情趣，是托物言志。"),
        // 文言文 · 内容概括与人物（3）
        q("sup-j-22","classical",.middle,"classical.summary",.developing,"曹刿认为可以追击齐军的根据是？",["视其辙乱，望其旗靡","齐军人多势众","鲁庄公已经下令","天色将晚"],0,"下车察看车辙混乱、旗帜倒下，确认是真溃败才追击。"),
        q("sup-j-23","classical",.middle,"classical.summary",.developing,"邹忌劝谏齐王采用的方式是？",["以自身比美小事类比国事，委婉讽谏","当面指责君王过错","上书直陈利害","借他人之口进谏"],0,"由家事推及国事，类比说理，使对方容易接受。"),
        q("sup-j-24","classical",.middle,"classical.summary",.challenge,"《出师表》中诸葛亮向后主提出的首要建议是？",["开张圣听，广开言路","赏罚分明、不偏私","亲贤臣、远小人","出师北伐、兴复汉室"],0,"第一条建议即广开言路，其后才依次提出赏罚与用人。"),
        // 现代文 · 议论文（4）
        q("sup-j-25","reading",.middle,"reading.argumentative",.developing,"议论文开头写“读书足以怡情”，这句话的作用是？",["提出本段的分论点","举出事实论据","总结全文","反驳对方观点"],0,"概括性判断句领起全段，属于分论点。"),
        q("sup-j-26","reading",.middle,"reading.argumentative",.foundation,"议论文中列举名人事例，属于哪类论据？",["事实论据","道理论据","比喻论证","对比论证"],0,"人物事例是客观事实，属于事实论据。"),
        q("sup-j-27","reading",.middle,"reading.argumentative",.developing,"文中出现“综上所述”，通常标志什么？",["得出结论","提出论题","举例论证","转入反面论述"],0,"“综上所述”用于收束归纳，引出结论。"),
        q("sup-j-28","reading",.middle,"reading.argumentative",.challenge,"先摆出对方观点再逐条批驳，这种写法属于？",["驳论，先破后立","立论，正面论证","举例论证","类比论证"],0,"先破对方论点，再立自己的观点，是驳论常见结构。"),
        // 现代文 · 开放探究（2）
        q("sup-j-29","reading",.middle,"reading.inquiry",.developing,"回答开放探究题，最核心的要求是？",["观点明确，并结合文本与生活说理","越新奇越好","完全复述原文","只抒发个人感受"],0,"开放不等于随意，仍要有观点、有依据、有条理。"),
        q("sup-j-30","reading",.middle,"reading.inquiry",.challenge,"就“成长”主题谈自己的看法，最恰当的做法是？",["从文本细节出发，联系自身经历印证","只讲别人的故事","下结论而不给理由","重复题目中的句子"],0,"文本依据是根，个人体验是枝，二者结合才成立。"),
        // 综合性学习 · 材料探究（4）
        q("sup-j-31","integrated",.middle,"integrated.material",.developing,"三则材料分别谈阅读、写作与交流，整合后的核心结论是？",["语文学习要读写结合、学以致用","阅读最重要","写作最难","交流可有可无"],0,"整合要兼顾三则信息，提炼共同指向。"),
        q("sup-j-32","integrated",.middle,"integrated.material",.developing,"材料中出现多组数据，探究时首先应该？",["概括数据的变化趋势","把数字全部抄下来","只看最大的那个数","忽略单位差异"],0,"先看趋势与比较，再提炼结论。"),
        q("sup-j-33","integrated",.middle,"integrated.material",.challenge,"两则材料观点相反，比较合理的态度是？",["辨析各自前提与适用范围，作出辩证判断","只选自己认同的一方","认定必有一方错误","把两说合并而不加分析"],0,"观点冲突常源于前提不同，应辨析而不是站队。"),
        q("sup-j-34","integrated",.middle,"integrated.material",.developing,"探究结果的表述要求是？",["简明、扣住材料，不随意引申","越长越充分","多用比喻","加入个人情绪"],0,"结论必须来自材料，语言简明，不作过度推断。"),
        // 作文 · 材料立意与论证（4）
        q("sup-j-35","writing",.middle,"writing.argument",.developing,"材料“一颗种子顶开石缝长成大树”，最佳立意是？",["微小的力量坚持下去也能创造奇迹","石头非常坚硬","应该多植树","种子很小很轻"],0,"抓住“顶开石缝”这一关键动作，立意落在坚持与力量上。"),
        q("sup-j-36","writing",.middle,"writing.argument",.developing,"论点为“坚持成就梦想”，下列事例最贴切的是？",["长期坚持练习、最终达成目标的事例","一次偶然获得的成功","别人对他的评价","对未来的想象"],0,"事例要能支撑“长期坚持—达成目标”这一因果链。"),
        q("sup-j-37","writing",.middle,"writing.argument",.challenge,"议论文举例之后还应该做什么？",["分析事例与论点的联系，揭示道理","立刻换下一个例子","重复一遍论点","细致描写场面"],0,"叙例之后要议例，否则事例与论点脱节。"),
        q("sup-j-38","writing",.middle,"writing.argument",.challenge,"议论文结尾要升华，恰当的做法是？",["由个别推及一般，联系人生或社会","重复开头的原句","提出一个新的疑问","不作收束戛然而止"],0,"升华要扩展意义，而不是简单重复。")
    ]

    // MARK: - 批次 8：按权重查缺补漏 · 小学补强（26）

    private static let supplementPrimary: [ChinQuestion] = [
        // 阅读策略（4）
        q("sup-p-01","reading",.primary,"reading.strategy",.foundation,"读一篇较长的文章，最先应该做的是？",["看题目和每段开头，把握整体脉络","逐字查字典","直接去做后面的题","只读第一段"],0,"题目与段首句能快速搭起文章框架。"),
        q("sup-p-02","reading",.primary,"reading.strategy",.foundation,"遇到不理解的词语，最好的办法是？",["联系上下文猜测意思，再查证确认","立刻跳过这一段","随便猜一个","抄下来不再管"],0,"上下文是理解词义的第一线索，查证可以确认。"),
        q("sup-p-03","reading",.primary,"reading.strategy",.developing,"既要读得快又要读懂，合适的做法是？",["带着问题读，抓住关键词句","用手指着逐字读","只读加粗的字","反复读第一段"],0,"有目标地扫读关键词，效率与理解可以兼顾。"),
        q("sup-p-04","reading",.primary,"reading.strategy",.developing,"读完一篇文章想记住内容，可以怎么做？",["用自己的话概括主要内容","把全文抄写一遍","只读标题","背诵第一段"],0,"概括是把内容转成自己的话，记得更牢。"),
        // 环境描写（3）
        q("sup-p-05","reading",.primary,"reading.environment",.foundation,"“窗外北风呼呼地刮着”，这句环境描写的作用是？",["交代天气寒冷，并烘托人物心情","说明窗户没有关","表示春天来了","介绍人物身份"],0,"自然环境既写天气，也为人物心情作铺垫。"),
        q("sup-p-06","reading",.primary,"reading.environment",.developing,"“教室安静得能听见针掉在地上的声音”，写出了？",["极其安静，突出紧张或专注","教室面积很大","地面很硬","同学们都睡着了"],0,"用夸张写静，强调当时的氛围。"),
        q("sup-p-07","reading",.primary,"reading.environment",.challenge,"开头写“夕阳把操场染成金色”，除了交代时间还可能？",["为后文定下温暖的基调","说明马上要下雨","介绍操场的大小","暗示比赛失败"],0,"景物的色彩常常暗示情感基调。"),
        // 开放探究（3）
        q("sup-p-08","reading",.primary,"reading.inquiry",.foundation,"学完《司马光》，最合理的启发是？",["遇到事情要冷静，动脑筋想办法","石头很危险","不要和同伴玩耍","水缸应该放低一些"],0,"砸缸救人体现的是冷静与机智。"),
        q("sup-p-09","reading",.primary,"reading.inquiry",.developing,"对故事中人物的做法发表看法，应该？",["先说观点，再举文中事例说明理由","只说喜欢或不喜欢","把故事情节复述一遍","把所有人物都批评一遍"],0,"观点加文本证据，看法才站得住。"),
        q("sup-p-10","reading",.primary,"reading.inquiry",.developing,"读完一篇科普文章之后，进一步可以做什么？",["提出新问题，并去查资料验证","合上书就算读完","只记住结论","改写故事的结局"],0,"探究从提问开始，再用资料去验证。"),
        // 作文 · 语言升格（4）
        q("sup-p-11","writing",.primary,"writing.language",.foundation,"把“他跑得很快”写得更生动，可改为？",["他像离弦的箭一样冲了出去","他跑得十分快","他的跑步速度很快","他很快地跑着"],0,"比喻让速度变得可见可感。"),
        q("sup-p-12","writing",.primary,"writing.language",.foundation,"把“我很高兴”写具体，最好的是？",["我乐得一蹦三尺高，嘴角怎么也压不下来","我非常高兴","我十分开心","我的心情不错"],0,"用动作和神态代替抽象的“高兴”。"),
        q("sup-p-13","writing",.primary,"writing.language",.developing,"“我看见了美丽的风景和动听的歌声”应改为？",["我看见了美丽的风景，听到了动听的歌声","我看见了美丽的风景和歌声","我听见了风景和歌声","我看见了动听的歌声"],0,"“看见”与“歌声”搭配不当，需要分开表述。"),
        q("sup-p-14","writing",.primary,"writing.language",.developing,"写人时让人物“活”起来的关键是？",["写具体的动作、语言、神态，而不只下结论","多用成语","写大量心理活动","把外貌写得很长"],0,"具体的言行神态比概括评价更能立住人物。"),
        // 新闻（3）
        q("sup-p-15","integrated",.primary,"integrated.news",.foundation,"新闻最重要的特点是？",["真实、及时、简明","生动、夸张、感人","篇幅长、议论多","多用比喻"],0,"新闻以事实为生命，讲究时效与简明。"),
        q("sup-p-16","integrated",.primary,"integrated.news",.developing,"新闻导语的作用是？",["用最简洁的话概括最重要的事实","详细描写事件细节","发表作者议论","介绍人物性格"],0,"导语在开头交代最核心的事实。"),
        q("sup-p-17","integrated",.primary,"integrated.news",.developing,"标题“我校读书节开幕”怎样改更好？",["我校第三届读书节昨日开幕","读书节开幕了","我校有活动","同学们真高兴"],0,"补上届次与时间，信息更完整、更醒目。"),
        // 活动方案与通知（3）
        q("sup-p-18","integrated",.primary,"integrated.activity",.foundation,"一份活动方案通常应包含？",["活动目的、时间地点、参加人员、过程与注意事项","只写时间","只写参加人员","只写个人感想"],0,"要素齐全，活动才具有可执行性。"),
        q("sup-p-19","integrated",.primary,"integrated.activity",.foundation,"写通知，正文必须写清？",["时间、地点、参加人、事项","当天的天气","个人感想","长篇的活动意义"],0,"通知的四要素缺一不可。"),
        q("sup-p-20","integrated",.primary,"integrated.activity",.developing,"活动总结主要写什么？",["过程、收获与改进建议","只写不足之处","只列表扬名单","把活动方案抄一遍"],0,"回顾过程、提炼收获、提出改进，才是总结。"),
        // 口语交际（3）
        q("sup-p-21","integrated",.primary,"integrated.oral",.foundation,"采访前最必要的准备是？",["明确主题、列好问题、约好时间","准备礼物","背诵长篇开场白","到现场临时想问题"],0,"有主题和问题提纲，采访才有方向。"),
        q("sup-p-22","integrated",.primary,"integrated.oral",.developing,"劝说同学少玩游戏，最得体的说法是？",["先肯定他的爱好，再说明影响，并提出替代活动","直接把手机没收","说玩游戏的人都没出息","请老师严厉批评他"],0,"先接纳再引导，才容易被对方接受。"),
        q("sup-p-23","integrated",.primary,"integrated.oral",.developing,"发言时紧张忘词，可以怎么做？",["看提纲、放慢语速、自然过渡","立刻跑下台","沉默很长时间","随便换一个话题"],0,"借助提纲稳住节奏，是实用的补救办法。"),
        // 图表解读（3）
        q("sup-p-24","integrated",.primary,"integrated.chart",.foundation,"看条形统计图，首先要看什么？",["标题、单位与每格代表的数量","图的颜色","图的大小","绘制者姓名"],0,"先读标题与单位，数据才有意义。"),
        q("sup-p-25","integrated",.primary,"integrated.chart",.developing,"折线图最适合表示什么？",["数量随时间的变化趋势","各部分所占的比例","数量的多少对比","人物的年龄"],0,"折线突出的是变化趋势。"),
        q("sup-p-26","integrated",.primary,"integrated.chart",.foundation,"扇形统计图中各部分之和是？",["整体，即 100%","最大的那一部分","任意数值","无法确定"],0,"扇形图表示的是部分与整体的关系。")
    ]

    // MARK: - 批次 9：模块覆盖修正 · 古诗词鉴赏全覆盖 + 薄弱知识点补齐（52）

    /// 权重依据：古诗词鉴赏是五大模块中唯一在前四轮没有补充的模块，
    /// 其 8 个知识点（小学/初中各 4 个）仍停在 7 题；同时补齐阅读、综合、写作与文言中题量最薄的知识点。
    private static let supplementRoundFive: [ChinQuestion] = [
        // 古诗词 · 小学（8）
        q("sup2-p-01","poetry",.primary,"poetry.word",.developing,"“停车坐爱枫林晚”中“坐”的意思是？",["因为","坐下","座位","正好"],0,"古汉语里“坐”可表原因，意为因为喜爱枫林晚景而停车。"),
        q("sup2-p-02","poetry",.primary,"poetry.word",.foundation,"“春眠不觉晓”中“晓”指什么？",["天刚亮的时候","知道","睡觉","春天"],0,"“晓”指天明，点出诗人沉睡不觉天亮的情态。"),
        q("sup2-p-03","poetry",.primary,"poetry.imagery",.foundation,"“儿童急走追黄蝶，飞入菜花无处寻”描绘的画面是？",["儿童追蝶、蝶入菜花，一派活泼的春日景象","儿童在捉迷藏","蝴蝶全都飞走了","菜花地里空无一人"],0,"黄蝶与菜花同色才“无处寻”，画面充满童趣。"),
        q("sup2-p-04","poetry",.primary,"poetry.imagery",.developing,"“天苍苍，野茫茫，风吹草低见牛羊”写出了草原怎样的特点？",["辽阔而生机勃勃","荒凉而寒冷","狭窄而安静","陡峭而险峻"],0,"“苍苍”“茫茫”写辽阔，风吹草低见牛羊写生机。"),
        q("sup2-p-05","poetry",.primary,"poetry.technique",.developing,"“碧玉妆成一树高，万条垂下绿丝绦”主要运用了什么手法？",["比喻，把柳枝比作绿丝带","拟人，把柳树写成美人","夸张，写树很高","反问，加强语气"],0,"“碧玉”“绿丝绦”都是比喻，写出柳树的翠绿柔美。"),
        q("sup2-p-06","poetry",.primary,"poetry.technique",.challenge,"“窗含西岭千秋雪，门泊东吴万里船”在写法上的特点是？",["对仗工整，时空跨度很大","通篇抒情","通篇议论","只用白描不加修饰"],0,"两句对仗，一写远景一写近景，时间与空间都被拉开。"),
        q("sup2-p-07","poetry",.primary,"poetry.emotion",.developing,"“谁言寸草心，报得三春晖”表达的情感是？",["对母爱的感激与难以报答之情","对春天的喜爱","对朋友的思念","对故乡的眷恋"],0,"以小草喻子女、以春晖喻母爱，感恩之情深挚。"),
        q("sup2-p-08","poetry",.primary,"poetry.emotion",.challenge,"“洛阳亲友如相问，一片冰心在玉壶”表达了诗人什么？",["坚守高洁清白品格的心志","思念亲友的悲伤","想要回家的急切","对官场的厌倦"],0,"“冰心”“玉壶”比喻纯洁无瑕的品格。"),
        // 古诗词 · 初中（8）
        q("sup2-j-01","poetry",.middle,"poetry.word",.challenge,"“造化钟神秀，阴阳割昏晓”中“割”字的妙处是？",["化静为动，写出泰山把山南山北分成明暗两半的雄伟","写出刀锋的锋利","写出天气的变化","写出树木的茂密"],0,"一个“割”字写出泰山的高峻与气势。"),
        q("sup2-j-02","poetry",.middle,"poetry.word",.challenge,"“黑云压城城欲摧”中“压”字的作用是？",["渲染敌军压境的紧张与危急","描写乌云很重","说明城墙不坚固","表现天气闷热"],0,"“压”字把危急形势写得如在眼前。"),
        q("sup2-j-03","poetry",.middle,"poetry.imagery",.developing,"“晴川历历汉阳树，芳草萋萋鹦鹉洲”的景象特点是？",["明丽清晰，却更衬出尾联的思乡之愁","萧瑟凄凉","荒凉破败","热闹喧哗"],0,"景物越清晰明丽，越反衬日暮引发的乡愁。"),
        q("sup2-j-04","poetry",.middle,"poetry.imagery",.challenge,"“角声满天秋色里，塞上燕脂凝夜紫”营造的氛围是？",["悲壮惨烈","轻松欢快","宁静优美","神秘莫测"],0,"号角、秋色与夜色中的凝血，构成悲壮的战场画面。"),
        q("sup2-j-05","poetry",.middle,"poetry.technique",.developing,"“忽如一夜春风来，千树万树梨花开”写雪，运用的手法是？",["比喻，以春花喻冬雪","拟人，把雪写活","夸张，写雪下得很大","借代，以梨花代雪"],0,"以梨花喻雪，是咏雪的千古名句。"),
        q("sup2-j-06","poetry",.middle,"poetry.technique",.challenge,"“东风不与周郎便，铜雀春深锁二乔”运用的写法是？",["用典，以反向假设评说历史","白描，直接叙事","对比，写古今之变","夸张，夸大战果"],0,"借赤壁典故作假设，抒发对历史机遇的感慨。"),
        q("sup2-j-07","poetry",.middle,"poetry.emotion",.developing,"“日暮乡关何处是？烟波江上使人愁”表达的情感是？",["浓重的思乡之愁","对美景的赞叹","怀才不遇的愤懑","对友人的不舍"],0,"日暮与烟波触发乡愁，是全诗情感的落点。"),
        q("sup2-j-08","poetry",.middle,"poetry.emotion",.developing,"“安得广厦千万间，大庇天下寒士俱欢颜”表达了诗人怎样的情怀？",["推己及人、忧国忧民","对个人住房的不满","对仕途的失望","对朋友的关切"],0,"由自身茅屋破败想到天下寒士，境界开阔。"),
        // 现代文阅读 · 小学（6）
        q("sup2-p-09","reading",.primary,"reading.expository",.developing,"说明文中“大约”“左右”这类词语能否删去？为什么？",["不能，它们体现说明文语言的准确与严密","能删，删去后更简洁","能删，不影响意思","都可以删，没有区别"],0,"限制性词语体现了说明文语言的准确性。"),
        q("sup2-p-10","reading",.primary,"reading.expository",.foundation,"说明文中使用列数字，主要作用是？",["使说明更准确具体、更有说服力","使文章更生动","增加文章的抒情性","引出下文的议论"],0,"列数字是为了准确说明事物的特征。"),
        q("sup2-p-11","reading",.primary,"reading.language",.developing,"“小草偷偷地从土里钻出来”中“偷偷地”“钻”好在哪里？",["把小草拟人化，写出春草破土而出的生机","说明小草长得很慢","说明没有人注意小草","说明土很硬"],0,"拟人化的词语让春草有了情态与活力。"),
        q("sup2-p-12","reading",.primary,"reading.language",.developing,"赏析一个句子，一般从哪里入手？",["修辞、关键词及其表达效果","只看字数的多少","只看是否用了成语","只看句子的长短"],0,"赏析要抓手法与关键词，再说明表达效果。"),
        q("sup2-p-13","reading",.primary,"reading.title",.developing,"给一篇写母爱的文章拟标题，最恰当的是？",["《那碗深夜的热汤面》","《记一件事》","《我的妈妈》","《我的家庭》"],0,"具体可感的细节标题既能概括内容，又含情感。"),
        q("sup2-p-14","reading",.primary,"reading.title",.foundation,"拟文章标题时主要应考虑什么？",["能概括主要内容或点明中心，并尽量有吸引力","越长越好","必须使用成语","必须出现人物姓名"],0,"标题要概括内容、点明中心，还要有吸引力。"),
        // 现代文阅读 · 初中（8）
        q("sup2-j-09","reading",.middle,"reading.expository",.foundation,"下列不属于说明顺序的是？",["总—分—总的论证结构","时间顺序","空间顺序","逻辑顺序"],0,"说明顺序有时间、空间、逻辑三种，论证结构属于议论文。"),
        q("sup2-j-10","reading",.middle,"reading.expository",.foundation,"“赵州桥非常雄伟，全长 50.82 米”使用了哪种说明方法？",["列数字","打比方","作比较","下定义"],0,"用具体数字说明规模，属于列数字。"),
        q("sup2-j-11","reading",.middle,"reading.title",.developing,"为以“诚信”为主题的文章选标题，最恰当的是？",["《一张迟到的欠条》","《诚信》","《谈品质》","《一件小事》"],0,"用具体事物承载抽象主题，更耐读、更有画面感。"),
        q("sup2-j-12","reading",.middle,"reading.title",.developing,"文章以“灯”为线索贯穿全文，标题拟为哪一项最好？",["《那盏不灭的灯》","《灯》","《照明工具》","《夜晚》"],0,"线索事物加上修饰语，既点线索又含情感。"),
        q("sup2-j-13","reading",.middle,"reading.language",.challenge,"赏析“月光如流水一般，静静地泻在这一片叶子和花上”，关键在于？",["“泻”字化静为动，写出月光的流动感","“叶子和花”是描写的对象","句子比较长","句子用了“如”字"],0,"动词化静为动，是这句赏析的核心。"),
        q("sup2-j-14","reading",.middle,"reading.language",.developing,"品味散文的语言，下列说法最恰当的是？",["结合语境，从关键词与修辞入手体会情感","只找用了修辞的句子","只背诵优美的句子","只看句子是否简短"],0,"品味语言必须回到具体语境。"),
        q("sup2-j-15","reading",.middle,"reading.inquiry",.challenge,"就“中学生是否应该使用手机”谈看法，较好的结构是什么？",["表明观点—列出理由—回应反方—作出总结","只说观点","只举例子","只抒发情绪"],0,"探究性表达要有观点、有理由，还要有一点思辨。"),
        q("sup2-j-16","reading",.middle,"reading.inquiry",.developing,"探究题要求“联系生活实际”，指的是？",["用自身或身边的真实经历印证观点","编造一个故事","把材料内容复述一遍","只要引用名人名言即可"],0,"联系生活要真实、贴切，并能印证观点。"),
        // 综合性学习 · 小学（4）
        q("sup2-p-15","integrated",.primary,"integrated.language",.foundation,"把“请您稍等”改得更得体，可以这样说？",["请您稍候片刻，我马上为您处理","等着，别急","等一下啊","你等会儿再说"],0,"礼貌用语要用敬辞，并说明接下来的安排。"),
        q("sup2-p-16","integrated",.primary,"integrated.language",.foundation,"给长辈打电话，开头最得体的是？",["您好，请问是张奶奶吗？我是小明","喂，你谁啊","张奶奶在吗","快叫张奶奶"],0,"先问好、自报姓名，是通话的基本礼貌。"),
        q("sup2-p-17","integrated",.primary,"integrated.slogan",.developing,"为“节约用水”拟宣传标语，最恰当的是？",["节约用水，从拧紧每一个水龙头开始","我们要节约用水","水很重要","请保护水资源"],0,"有具体行动指引的标语更有号召力。"),
        q("sup2-p-18","integrated",.primary,"integrated.slogan",.foundation,"拟宣传标语时，最重要的是？",["主题鲜明、语言简练、便于传诵","字数越多越好","必须使用对偶","必须使用比喻"],0,"标语讲究简明有力、朗朗上口。"),
        // 综合性学习 · 初中（4）
        q("sup2-j-17","integrated",.middle,"integrated.language",.foundation,"下列表达最得体的是？",["多亏您的指点，让我少走了很多弯路","喂，把书递给我","你懂什么","这事不归我管"],0,"致谢要有对象、有具体内容，语气诚恳。"),
        q("sup2-j-18","integrated",.middle,"integrated.language",.developing,"在正式场合发言，语言应当？",["简明、得体、有条理","尽量口语化","多用网络流行语","越含蓄越好"],0,"正式场合讲究简明得体、条理清晰。"),
        q("sup2-j-19","integrated",.middle,"integrated.slogan",.developing,"为“全民阅读”活动拟标语，最恰当的是？",["书香润泽心灵，阅读点亮人生","要多读书","读书好，读好书","大家一起看书吧"],0,"对偶句凝练整齐，富有感染力。"),
        q("sup2-j-20","integrated",.middle,"integrated.slogan",.foundation,"为班级读书角拟标语，最好做到？",["点明活动主题，并巧用修辞增强感染力","把通知内容抄上去","只写一个“书”字","照抄名人名言"],0,"标语要短小有力、点明主题。"),
        // 作文 · 小学（2）
        q("sup2-p-19","writing",.primary,"writing.application",.developing,"写《我的老师》，选材最好的是？",["老师冒雨为我补课的一件小事，并写出细节","老师的姓名和年龄","老师每天都很辛苦","老师教会了我很多"],0,"具体小事加细节描写，比概括评价更动人。"),
        q("sup2-p-20","writing",.primary,"writing.application",.foundation,"作文开头“开门见山”的作用是？",["直接入题，让读者迅速把握写作对象","设置悬念","渲染气氛","总结全文"],0,"开门见山简洁明了，便于迅速入题。"),
        // 作文 · 初中（6）
        q("sup2-j-21","writing",.middle,"writing.application",.developing,"半命题作文“___让我成长”，补题最好的是？",["那次演讲失败让我成长","挫折让我成长","生活让我成长","时间让我成长"],0,"补题越具体，越容易写出独特的体验。"),
        q("sup2-j-22","writing",.middle,"writing.application",.developing,"记叙文的详略安排依据是什么？",["根据中心需要决定，能突出中心的详写","按字数多少决定","按时间先后决定","按自己是否喜欢决定"],0,"详略服务于中心，不能凭个人喜好。"),
        q("sup2-j-23","writing",.middle,"writing.detail",.developing,"要写出人物的心理，最好的办法是？",["通过动作、神态与环境间接表现","反复使用“他很伤心”这类概括","堆砌形容词","引用他人的评价"],0,"间接描写比直接概括更能让读者感同身受。"),
        q("sup2-j-24","writing",.middle,"writing.detail",.challenge,"场面描写要出彩，应该注意？",["点面结合，既有全景又有特写","只写整体轮廓","只写一个人","只写听到的声音"],0,"点面结合才能让场面层次分明。"),
        q("sup2-j-25","writing",.middle,"writing.structure",.developing,"记叙文中设置悬念的作用是？",["激发阅读兴趣，使情节曲折","增加文章的字数","显示作者博学","交代故事的结局"],0,"悬念能在开头抓住读者。"),
        q("sup2-j-26","writing",.middle,"writing.structure",.developing,"文章结尾与开头反复提到同一事物，这种写法叫？",["首尾呼应","开门见山","卒章显志","承上启下"],0,"首尾呼应使结构完整、主题突出。"),
        // 文言文 · 初中（4）
        q("sup2-j-27","classical",.middle,"classical.summary",.challenge,"《桃花源记》中渔人“处处志之”却“不复得路”，用意是？",["暗示这样的理想社会在现实中并不存在","说明渔人记性不好","说明路途十分遥远","批评渔人不守信用"],0,"虚实结合，寄托对理想社会的向往与无奈。"),
        q("sup2-j-28","classical",.middle,"classical.summary",.developing,"《马说》中的“千里马”比喻什么？",["人才","马匹","统治者","马车"],0,"托物寓意，千里马喻人才，食马者喻统治者。"),
        q("sup2-j-29","classical",.middle,"classical.appreciation",.developing,"《爱莲说》中写菊与牡丹，作用是？",["衬托莲的高洁，突出君子之德","介绍花卉知识","说明作者喜爱花卉","批判世人只爱牡丹"],0,"正衬与反衬并用，突出莲的形象。"),
        q("sup2-j-30","classical",.middle,"classical.appreciation",.challenge,"《小石潭记》中“凄神寒骨，悄怆幽邃”抒发了什么？",["被贬后的孤寂悲凉","游览山水的愉悦","对朋友的思念","对山水的赞美"],0,"景中寓情，清幽之景触发贬谪之悲。"),
        // 文言文 · 小学（2）
        q("sup2-p-21","classical",.primary,"classical.summary",.foundation,"《囊萤夜读》中车胤的做法说明他？",["家境贫寒却勤奋好学","家里十分富有","喜欢捕捉萤火虫","夜里不爱睡觉"],0,"“囊萤”是条件艰苦仍坚持读书的典型事例。"),
        q("sup2-p-22","classical",.primary,"classical.summary",.foundation,"《铁杵成针》告诉我们的道理是？",["只要功夫深，坚持不懈就能成功","铁棒可以磨成针","老妇人很有力气","李白不爱学习"],0,"以磨针喻恒心，讲的是坚持的力量。")
    ]

    // MARK: - 批次 10：按知识点均衡扩容（112：小学 58、初中 54）

    /// 权重依据：第五轮之后所有知识点都已达到权重下限，但练习量普遍偏薄。
    /// 本轮按知识点覆盖学段整体加厚——两学段知识点各 +4（每学段 2 道），
    /// 小学专属知识点 +3、初中专属知识点 +2，使每个知识点都能撑起一轮巩固练习。
    private static let supplementRoundSix: [ChinQuestion] = [
        // 现代文阅读 · 人物形象与细节（小学 2 / 初中 2）
        q("sup3-p-01","reading",.primary,"reading.character",.developing,"“他站在讲台上，手一直捏着衣角，声音却很稳。”这处描写主要表现人物？",["内心紧张但努力保持镇定","毫不在意这次发言","对发言内容很不熟悉","想尽快结束发言"],0,"“捏衣角”写紧张，“声音很稳”写克制，内外反差见出人物性格。"),
        q("sup3-p-02","reading",.primary,"reading.character",.developing,"判断人物品质时，最可靠的依据是？",["人物的具体言行以及旁人的反应","作者直接给出的评价","人物的外貌描写","人物的身份和职业"],0,"言行是可核对的证据，比概括性的评价更可靠。"),
        q("sup3-j-01","reading",.middle,"reading.character",.developing,"小说写“他把伞往同伴那边挪了挪，自己半边肩膀湿透了”，其作用是？",["用细节表现人物舍己为人的品质","说明当时雨下得很大","交代故事发生的季节","暗示两人即将分别"],0,"挪伞与湿透的肩膀是可感的行为，胜过直接赞美。"),
        q("sup3-j-02","reading",.middle,"reading.character",.challenge,"把人物放进矛盾冲突中去分析，主要好处是？",["能看清人物的选择与价值取向","能增加文章的字数","可以省去环境描写","可以不必引用原文"],0,"冲突逼出选择，选择最能暴露人物的价值取向。"),
        // 现代文阅读 · 证据与信息提取（小学 2 / 初中 2）
        q("sup3-p-03","reading",.primary,"reading.evidence",.foundation,"要证明“奶奶每天起得很早”，最有效的证据是？",["直接写时间与动作的句子","描写天气的句子","文章的标题","插图下面的说明"],0,"时间和动作是最直接、可核对的信息。"),
        q("sup3-p-04","reading",.primary,"reading.evidence",.developing,"题目问“从哪里可以看出他很着急”，答题时应？",["摘出描写动作或神态的原句，再作说明","只写“他很着急”","把全文大意复述一遍","另编一个类似的例子"],0,"先有原文依据，再有分析，答案才站得住。"),
        q("sup3-j-03","reading",.middle,"reading.evidence",.developing,"做信息筛选题，最稳妥的做法是？",["逐项回到原文比对，排除无依据的选项","凭大致印象直接选择","选表述最长的那一项","选出现次数最多的那一项"],0,"唯一可靠的方法是回到原文逐项比对。"),
        q("sup3-j-04","reading",.middle,"reading.evidence",.developing,"文中出现“据报道”“据统计”这类词语，其作用是？",["标明信息来源，增强可信度","表示作者自己也拿不准","增加文章的抒情色彩","引出下一段的景物描写"],0,"交代来源是为了让信息显得可查、可信。"),
        // 现代文阅读 · 结构·线索·思路（小学 2 / 初中 2）
        q("sup3-p-05","reading",.primary,"reading.structure",.developing,"文章先写“我”讨厌数学，再写一次被鼓励后发生改变，这种写法是？",["先抑后扬","开门见山","卒章显志","借景抒情"],0,"先压低再抬高，前后对比更突出转变。"),
        q("sup3-p-06","reading",.primary,"reading.structure",.foundation,"“这件事，我至今想起来仍觉得温暖。”放在结尾的作用是？",["收束全文并点明中心","引出下文的回忆","设置悬念","描写环境"],0,"结尾句承担总结与点题的作用。"),
        q("sup3-j-05","reading",.middle,"reading.structure",.developing,"文中多次出现“那盏灯”，它在结构上的作用是？",["作为线索贯穿全文","交代故事的结局","制造悬念","转换叙述人称"],0,"反复出现并推动情节的事物，往往就是行文线索。"),
        q("sup3-j-06","reading",.middle,"reading.structure",.developing,"判断某段是否起“承上启下”作用，依据是？",["既总结上文内容，又引出下文话题","段落中出现了时间词语","这一段篇幅最长","这一段位于文章开头"],0,"承上启下看的是内容上的衔接关系，不是位置。"),
        // 现代文阅读 · 标题含义（小学 2 / 初中 2）
        q("sup3-p-07","reading",.primary,"reading.title",.developing,"《第一次洗碗》与《我学会了分担》相比，后者好在？",["点明了事件背后的意义","字数更少","使用了动词","采用了第一人称"],0,"好标题应当能看见事情之外的那层意思。"),
        q("sup3-p-08","reading",.primary,"reading.title",.developing,"标题为《爸爸的旧自行车》，最可能写的主题是？",["借一件旧物写亲情与记忆","介绍自行车的构造","说明交通安全的重要","描写城市的变化"],0,"以物为题，多半是借物写人、借物抒情。"),
        q("sup3-j-07","reading",.middle,"reading.title",.developing,"用设问句作文章标题，主要作用是？",["引发读者思考，并提示文章内容","说明作者对此存疑","增加文章的篇幅","表示故事没有结局"],0,"设问式标题既设疑又指向内容。"),
        q("sup3-j-08","reading",.middle,"reading.title",.challenge,"评价一个标题的优劣，最重要的标准是？",["是否概括内容、暗示主旨并吸引阅读","是否使用了修辞手法","是否包含人物姓名","是否足够简短"],0,"概括、点旨、吸引阅读，是标题的三项基本功。"),
        // 现代文阅读 · 语言赏析（小学 2 / 初中 2）
        q("sup3-p-09","reading",.primary,"reading.language",.foundation,"“太阳公公露出了笑脸”运用的修辞手法是？",["拟人","比喻","夸张","设问"],0,"把太阳当作人来写，赋予人的表情。"),
        q("sup3-p-10","reading",.primary,"reading.language",.developing,"赏析“树叶在风中沙沙地笑”，说法正确的是？",["用拟人写出树叶的欢快，也传达作者的愉悦","说明风刮得很大","说明树叶很脆","说明马上要下雨"],0,"景物带上了人的情态，其实是人物心情的外化。"),
        q("sup3-j-09","reading",.middle,"reading.language",.developing,"赏析词语的基本步骤是？",["解释本义—结合语境说含义—分析表达效果","只查字典抄注释","只说明读音","只指出词性"],0,"由本义到语境义再到效果，是完整的赏析链。"),
        q("sup3-j-10","reading",.middle,"reading.language",.challenge,"“他的话像一把钝刀，慢慢地割着我的心”好在哪里？",["把抽象的心理痛苦写得具体可感","说明那把刀很不锋利","说明他说话语速很慢","说明作者受了外伤"],0,"比喻把看不见的痛感转成可以感知的动作。"),
        // 现代文阅读 · 说明文阅读（小学 2 / 初中 2）
        q("sup3-p-11","reading",.primary,"reading.expository",.foundation,"说明文在开头讲一个小故事，通常是为了？",["引出说明对象，激发阅读兴趣","增加文章的长度","发表作者的议论","交代人物关系"],0,"故事只是引子，真正目的是带出说明对象。"),
        q("sup3-p-12","reading",.primary,"reading.expository",.foundation,"“松鼠的尾巴像一把伞”使用了哪种说明方法？",["打比方","列数字","作比较","下定义"],0,"用熟悉的事物比方陌生的事物，属于打比方。"),
        q("sup3-j-11","reading",.middle,"reading.expository",.developing,"说明文中引用谚语或诗句，主要作用是？",["增强说明的生动性与说服力","增加文章的抒情意味","代替必要的科学数据","引出人物故事"],0,"引用能让说明更有画面感和说服力。"),
        q("sup3-j-12","reading",.middle,"reading.expository",.challenge,"判断说明文语言是否准确，主要看？",["限制性词语使用是否恰当","是否多用成语","句子是否简短","是否使用第一人称"],0,"“大约”“主要”“一般”这类限制词，是准确性的关键。"),
        // 现代文阅读 · 开放探究（小学 2 / 初中 2）
        q("sup3-p-13","reading",.primary,"reading.inquiry",.developing,"读完《王戎不取道旁李》，最值得学习的是？",["善于观察并作出推理判断","不喜欢吃李子","跑得比同伴快","喜欢和大家一起玩"],0,"由现象推出结论，是这个故事的核心价值。"),
        q("sup3-p-14","reading",.primary,"reading.inquiry",.foundation,"表达看法时加上“因为……所以……”，作用是？",["把观点和理由连起来，更有说服力","让句子变得更长","让语气变得更强烈","让内容变得更生动"],0,"因果关联词能把理由显性化。"),
        q("sup3-j-13","reading",.middle,"reading.inquiry",.developing,"探究题要求“结合材料和生活实际”，指的是？",["从材料出发，用真实经历印证并加以分析","脱离材料自由发挥","把材料内容原样复述","只引用名人名言"],0,"材料是根，生活体验是枝叶，二者要结合。"),
        q("sup3-j-14","reading",.middle,"reading.inquiry",.challenge,"对同一现象存在两种不同看法，较妥当的处理是？",["辨析各自的依据，作出有条件的判断","认定其中只有一种正确","两边各打五十大板","回避问题不作判断"],0,"思辨不等于和稀泥，而是说清各自成立的条件。"),
        // 现代文阅读 · 环境描写（小学 3）
        q("sup3-p-15","reading",.primary,"reading.environment",.developing,"“雨哗哗地下着，屋里的灯一直亮着”，这句环境描写与情节的关系是？",["用雨夜烘托家人等待的焦急","说明房屋已经很旧","交代故事发生的季节","介绍人物的职业"],0,"雨夜与长明的灯共同指向等待与牵挂。"),
        q("sup3-p-16","reading",.primary,"reading.environment",.developing,"把环境描写放在人物出场之前，主要作用是？",["为人物出场营造氛围、作铺垫","交代故事的结局","总结上文内容","转换叙述视角"],0,"先布景再出场，人物一露面就带着情绪。"),
        q("sup3-p-17","reading",.primary,"reading.environment",.developing,"“风停了，阳光洒满小院”出现在结尾，情感基调是？",["明朗温暖，暗示心情转好","紧张不安","悲凉伤感","平淡无奇"],0,"景物由阴转晴，往往对应心情的转折。"),
        // 现代文阅读 · 阅读策略（小学 3）
        q("sup3-p-18","reading",.primary,"reading.strategy",.developing,"阅读时随手作批注，主要好处是？",["记录思考过程，帮助深入理解","让书页看起来更美观","加快书写速度","代替背诵"],0,"批注是把阅读时的想法固定下来。"),
        q("sup3-p-19","reading",.primary,"reading.strategy",.foundation,"读叙事性作品时，理清“起因—经过—结果”属于？",["整体把握文章思路","品味语言","分析修辞","了解作者生平"],0,"理清脉络属于整体感知层面的策略。"),
        q("sup3-p-20","reading",.primary,"reading.strategy",.challenge,"一篇文章读不懂，比较合适的做法是？",["放慢速度重读关键句，并查阅背景资料","立刻换一本书","只读开头的段落","把全文抄写一遍"],0,"回读关键句与补充背景，是有效的修复办法。"),
        // 现代文阅读 · 议论文阅读（初中 2）
        q("sup3-j-15","reading",.middle,"reading.argumentative",.foundation,"议论文中引用“诚者，天之道也”这类句子，属于？",["道理论据","事实论据","比喻论证","举例论证"],0,"引用经典言论属于道理论据。"),
        q("sup3-j-16","reading",.middle,"reading.argumentative",.developing,"议论文语言的基本要求是？",["准确、严密、有逻辑性","华丽、铺陈","含蓄、委婉","幽默、夸张"],0,"议论以理服人，语言首先要经得起推敲。"),
        // 文言文 · 实词（小学 2 / 初中 2）
        q("sup3-p-21","classical",.primary,"classical.word",.foundation,"“守株待兔”中“守”的意思是？",["守候、等待","保卫","遵守","看管"],0,"“守株”即守在树桩旁等待，取守候义。"),
        q("sup3-p-22","classical",.primary,"classical.word",.developing,"“兔走触株，折颈而死”中“走”的意思是？",["跑","行走","离开","经过"],0,"古汉语中“走”相当于今天的“跑”，跑才可能撞上树桩。"),
        q("sup3-j-17","classical",.middle,"classical.word",.challenge,"“便要还家”中“要”的意思是？",["通“邀”，邀请","要求","重要","需要"],0,"“要”通“邀”，读 yāo，意为邀请。"),
        q("sup3-j-18","classical",.middle,"classical.word",.developing,"“率妻子邑人来此绝境”中“妻子”的古义是？",["妻子和儿女","只指男子的配偶","妻子的兄弟","家族中的长辈"],0,"古汉语中“妻子”是两个词，指妻与子女。"),
        // 文言文 · 内容概括与人物（小学 2 / 初中 2）
        q("sup3-p-23","classical",.primary,"classical.summary",.developing,"《守株待兔》告诉我们的道理是？",["不能把偶然当必然，更不能心存侥幸","要多在树桩旁等待","兔子跑得非常快","那位农夫十分勤劳"],0,"偶然得兔不可复制，故事讽刺的是侥幸心理。"),
        q("sup3-p-24","classical",.primary,"classical.summary",.challenge,"《王戎不取道旁李》中王戎判断李子是苦的，依据是？",["树长在路边却果实繁多，若是甜李早被摘光","李子的颜色发青","他曾经尝过一颗","别人事先告诉了他"],0,"由“道旁”与“多子”推出“必苦”，是典型推理。"),
        q("sup3-j-19","classical",.middle,"classical.summary",.foundation,"《陋室铭》的中心句是？",["斯是陋室，惟吾德馨","山不在高，有仙则名","苔痕上阶绿，草色入帘青","南阳诸葛庐，西蜀子云亭"],0,"“惟吾德馨”一句统摄全篇，是全文主旨所在。"),
        q("sup3-j-20","classical",.middle,"classical.summary",.challenge,"《记承天寺夜游》中作者自称“闲人”，其含义是？",["既有赏月的闲情雅致，又含被贬的淡淡自嘲","指没有工作的人","指喜欢安静的人","指夜里睡不着的人"],0,"“闲”字兼有清闲与失意两层意味，是全文的关键。"),
        // 文言文 · 虚词（初中 2）
        q("sup3-j-21","classical",.middle,"classical.function",.challenge,"“予独爱莲之出淤泥而不染”中“之”的作用是？",["取消句子独立性，不译","代词，指莲","结构助词，相当于“的”","动词，意为“去”"],0,"主谓之间的“之”取消句子独立性，无需译出。"),
        q("sup3-j-22","classical",.middle,"classical.function",.developing,"“学而不思则罔”中的“而”表示什么关系？",["转折","并列","承接","修饰"],0,"学与思未能结合，句意转折，相当于“却”。"),
        // 文言文 · 特殊句式（初中 2）
        q("sup3-j-23","classical",.middle,"classical.sentence",.challenge,"“微斯人，吾谁与归”属于哪种特殊句式？",["宾语前置，疑问代词“谁”作宾语前置","定语后置","状语后置","被动句"],0,"疑问代词作宾语时要前置，正常语序为“吾与谁归”。"),
        q("sup3-j-24","classical",.middle,"classical.sentence",.developing,"“见渔人，乃大惊”一句省略了什么成分？",["主语（村中人）","谓语","宾语","状语"],0,"承前省略主语，看见渔人而吃惊的是村中人。"),
        // 文言文 · 翻译（初中 2）
        q("sup3-j-25","classical",.middle,"classical.translation",.challenge,"“先天下之忧而忧，后天下之乐而乐”应译为？",["在天下人忧虑之前先忧虑，在天下人快乐之后才快乐","先为天下担忧，再为天下享乐","天下的忧愁与快乐都要亲身经历","比天下人更早忧虑，也更早快乐"],0,"两个“先”“后”都表时间次序，突出以天下为己任的襟怀。"),
        q("sup3-j-26","classical",.middle,"classical.translation",.developing,"文言翻译的基本原则是？",["直译为主、字字落实，必要时调整语序","意译为主、可以自由发挥","只翻译实词即可","只要说出大意即可"],0,"先落实每个词，再按现代汉语习惯调顺语序。"),
        // 文言文 · 写法与主旨（初中 2）
        q("sup3-j-27","classical",.middle,"classical.appreciation",.challenge,"《岳阳楼记》先写“淫雨霏霏”再写“春和景明”，作用是？",["一悲一喜形成对比，引出更高的境界","依次描写四季景色","说明岳阳楼的地理位置","介绍当地的气候特点"],0,"两种景象引出两种心情，再翻出“不以物喜，不以己悲”。"),
        q("sup3-j-28","classical",.middle,"classical.appreciation",.developing,"《陋室铭》结尾引“孔子云：何陋之有”，用意是？",["借圣人之言作结，强调德馨则陋室不陋","说明孔子曾住过陋室","引出下文的描写","表示作者自己尚有疑问"],0,"引经典收束，是为了把主旨再提高一层。"),
        // 古诗词 · 意象与画面（小学 2 / 初中 2）
        q("sup3-p-25","poetry",.primary,"poetry.imagery",.foundation,"“两个黄鹂鸣翠柳，一行白鹭上青天”中的主要意象是？",["黄鹂、翠柳、白鹭、青天","只有黄鹂和翠柳","只有白鹭和青天","只有柳树和天空"],0,"四个意象并置，构成明丽的春日画面。"),
        q("sup3-p-26","poetry",.primary,"poetry.imagery",.developing,"“孤帆远影碧空尽，唯见长江天际流”的画面特点是？",["辽阔悠远，含着久久凝望的别情","热闹繁华","萧瑟荒凉","急促紧张"],0,"视线随孤帆远去，画面越远，别情越长。"),
        q("sup3-j-29","poetry",.middle,"poetry.imagery",.foundation,"“大漠孤烟直，长河落日圆”营造出的画面是？",["雄浑壮阔的边塞景象","凄凉破败的战场","繁忙喧闹的渡口","幽静深邃的山林"],0,"大、孤、直、长、圆几个字共同撑起辽阔的边塞感。"),
        q("sup3-j-30","poetry",.middle,"poetry.imagery",.challenge,"“枯藤老树昏鸦，小桥流水人家”在写景上的特点是？",["意象并列，白描中见萧瑟与温情的对照","使用比喻","使用夸张","通篇议论"],0,"名词意象直接并置，不加连接却自成画面。"),
        // 古诗词 · 炼字炼句（小学 2 / 初中 2）
        q("sup3-p-27","poetry",.primary,"poetry.word",.foundation,"“春风吹又生”中的“生”字写出了野草的？",["顽强的生命力","生长速度","颜色","高度"],0,"一个“生”字写尽野火烧不尽的生命力。"),
        q("sup3-p-28","poetry",.primary,"poetry.word",.challenge,"“春风又绿江南岸”中“绿”字的妙处是？",["形容词作动词，写出春风带来的勃勃生机","说明江水本身是绿色的","说明岸边长满了绿草","说明春风是绿色的"],0,"“绿”字带出动态，把看不见的春风写成可见的颜色。"),
        q("sup3-j-31","poetry",.middle,"poetry.word",.challenge,"“感时花溅泪，恨别鸟惊心”中“溅”“惊”二字的表达效果是？",["移情于物，把花、鸟人格化以写尽忧国之痛","写花瓣上沾着露水","写鸟儿受惊飞走","写春天景色的美丽"],0,"诗人把自己的悲痛移到花、鸟身上，更显沉痛。"),
        q("sup3-j-32","poetry",.middle,"poetry.word",.challenge,"“采菊东篱下，悠然见南山”中的“见”能否改为“望”？",["不能，“见”是无意间映入眼帘，更显悠然","能，两个字意思完全相同","不能，因为“望”字更押韵","能，“望”字表达得更清楚"],0,"“见”出于无意，正合“悠然”；“望”则有意为之。"),
        // 古诗词 · 表达技巧（小学 2 / 初中 2）
        q("sup3-p-29","poetry",.primary,"poetry.technique",.foundation,"“飞流直下三千尺，疑是银河落九天”主要运用了？",["夸张与比喻","拟人与排比","反问与设问","借代与反复"],0,"三千尺是夸张，银河是比喻，二者结合写瀑布。"),
        q("sup3-p-30","poetry",.primary,"poetry.technique",.developing,"“桃花潭水深千尺，不及汪伦送我情”运用的手法是？",["衬托，以潭水之深衬托友情更深","比喻，把友情比作潭水","夸张，写潭水非常深","拟人，把潭水写得像人"],0,"先言潭水之深，再以“不及”反衬情谊之厚。"),
        q("sup3-j-33","poetry",.middle,"poetry.technique",.developing,"“乡书何处达？归雁洛阳边”运用的写法是？",["设问并借归雁传书，表达思乡之情","反问，加强语气","用典，借用前人典故","对比，写古今之变"],0,"自问自答是设问，托雁传书是传统的寄情方式。"),
        q("sup3-j-34","poetry",.middle,"poetry.technique",.challenge,"“沉舟侧畔千帆过，病树前头万木春”的写法与含义是？",["比喻，借新陈代谢的景象表达豁达进取","白描，只写江上所见","夸张，写船多树多","用典，化用前人诗句"],0,"以沉舟、病树自比，却从千帆、万木中见出生机。"),
        // 古诗词 · 思想感情（小学 2 / 初中 2）
        q("sup3-p-31","poetry",.primary,"poetry.emotion",.foundation,"“独在异乡为异客，每逢佳节倍思亲”表达的情感是？",["节日里倍加浓烈的思乡念亲之情","对节日热闹场面的喜爱","对异乡风光的欣赏","对旅途劳顿的抱怨"],0,"“异客”与“倍思亲”直接点出节日里的思亲之切。"),
        q("sup3-p-32","poetry",.primary,"poetry.emotion",.developing,"“儿童散学归来早，忙趁东风放纸鸢”表达的情感是？",["对春光与童趣的喜爱","对读书的厌倦","对东风的畏惧","对故乡的思念"],0,"归早、趁风、放鸢，写的是春日里的快活。"),
        q("sup3-j-35","poetry",.middle,"poetry.emotion",.developing,"“会当凌绝顶，一览众山小”抒发了诗人怎样的情感？",["不怕困难、俯视一切的雄心与豪情","登高望远的闲适","对山路崎岖的抱怨","对友人的思念"],0,"“会当”是决心，“一览众山小”是胸襟。"),
        q("sup3-j-36","poetry",.middle,"poetry.emotion",.developing,"“但愿人长久，千里共婵娟”表达的是？",["对亲人的美好祝愿与旷达胸怀","对月夜景色的赞美","被贬谪后的愤懑","对战争的忧虑"],0,"由个人离别推及人间共愿，是旷达的祝愿。"),
        // 考场作文 · 审题与选材（小学 2 / 初中 2）
        q("sup3-p-33","writing",.primary,"writing.topic",.foundation,"写《一次难忘的尝试》，选材最合适的是？",["第一次独自坐公交车去外婆家","我的一天","我的妈妈","读书的好处"],0,"“尝试”要求写出第一次做某事的过程与感受。"),
        q("sup3-p-34","writing",.primary,"writing.topic",.developing,"审题时首先要弄清楚的是？",["写作对象、范围与重点","文章要写多少字","用哪种修辞手法","用第几人称"],0,"对象、范围、重点，是审题的三个要点。"),
        q("sup3-j-37","writing",.middle,"writing.topic",.challenge,"命题作文《这也是一种力量》中的“也”字提示？",["要写看似平常却蕴含力量的人和事","要写非常强大的事物","必须写成议论文","必须写成寓言"],0,"“也”意味着转换视角，从寻常处发现力量。"),
        q("sup3-j-38","writing",.middle,"writing.topic",.developing,"材料作文审题的关键一步是？",["找准材料的核心词与命题意图","把材料原文抄进作文","找出最长的那一句","先确定使用哪种修辞"],0,"抓住核心词，立意才不会跑偏。"),
        // 考场作文 · 细节描写（小学 2 / 初中 2）
        q("sup3-p-35","writing",.primary,"writing.detail",.developing,"要把“妈妈很辛苦”写具体，最好的做法是？",["写她深夜还在灯下为我缝纽扣的动作与神态","反复写“妈妈真辛苦”","写清楚妈妈的姓名","介绍家里有几口人"],0,"具体的动作和神态，比反复感叹更有力量。"),
        q("sup3-p-36","writing",.primary,"writing.detail",.developing,"描写人物动作时，最重要的是？",["把动作拆解成一连串具体动作","多用形容词","把动作写得很长","先写明动作发生的时间"],0,"分解动作，画面才连贯、可感。"),
        q("sup3-j-39","writing",.middle,"writing.detail",.developing,"细节描写的主要作用是？",["使内容具体可感，突出人物或主题","增加文章的篇幅","展示作者的词汇量","代替情节安排"],0,"细节服务于人物与主题，不是装饰。"),
        q("sup3-j-40","writing",.middle,"writing.detail",.challenge,"写“等待”时的焦急，最细腻的是？",["反复看表、来回踱步、听到脚步声就张望","我很着急","时间过得很慢","我等了很久"],0,"用可观察的行为代替抽象的心理概括。"),
        // 考场作文 · 结构与首尾（小学 2 / 初中 2）
        q("sup3-p-37","writing",.primary,"writing.structure",.foundation,"记叙文开头写“那天的雨下得很大”，最可能的作用是？",["交代环境并为下文情节作铺垫","说明当天的天气","介绍主要人物","总结全文内容"],0,"开头的环境描写通常兼有交代与铺垫两重作用。"),
        q("sup3-p-38","writing",.primary,"writing.structure",.developing,"一篇写“学骑车”的作文，结尾最好？",["写出收获或感悟，并回应题目","戛然而止不作收束","再补一段环境描写","提出问题而不作回答"],0,"结尾要点明收获，并回扣题目。"),
        q("sup3-j-41","writing",.middle,"writing.structure",.developing,"记叙文中穿插一段回忆，这种叙述方式是？",["插叙","顺叙","倒叙","补叙"],0,"在顺叙过程中插入相关片段，属于插叙。"),
        q("sup3-j-42","writing",.middle,"writing.structure",.developing,"安排文章层次时，过渡句的作用是？",["承上启下，使衔接自然","增加抒情色彩","引出人物对话","交代时间地点"],0,"过渡句负责把前后内容接顺。"),
        // 考场作文 · 应用文写作（小学 2 / 初中 2）
        q("sup3-p-39","writing",.primary,"writing.application",.foundation,"写《给远方朋友的一封信》，正文开头应先？",["问候对方，并说明写信的缘由","直接提出自己的要求","描写当地的天气","介绍学校的历史"],0,"书信开头先问候，再说明为什么写这封信。"),
        q("sup3-p-40","writing",.primary,"writing.application",.foundation,"写“通知”时，落款处应写清？",["发出通知的单位或个人以及日期","收通知人的姓名","当天的天气情况","活动感想"],0,"落款标明发文者与日期，通知才有效力。"),
        q("sup3-j-43","writing",.middle,"writing.application",.developing,"写演讲稿，开头最重要的是？",["称呼得体，并尽快点明话题以抓住听众","作长篇的自我介绍","罗列大量数据","先讲一个笑话暖场"],0,"演讲开头要迅速建立与听众的联系。"),
        q("sup3-j-44","writing",.middle,"writing.application",.developing,"写“倡议书”，正文部分最重要的是？",["说明倡议的背景、内容与具体要求","介绍自己的经历","抒发强烈的感情","描写周围环境"],0,"倡议书要让读者知道做什么、怎么做。"),
        // 考场作文 · 语言升格与修改（小学 3）
        q("sup3-p-41","writing",.primary,"writing.language",.foundation,"把“教室里很安静”写得更生动，可改为？",["教室里静得连一根针掉在地上都能听见","教室里非常安静","教室里没有一点声音","大家都不说话"],0,"夸张能放大感受，让“安静”变得可感。"),
        q("sup3-p-42","writing",.primary,"writing.language",.developing,"“我看见了他高兴的笑声”这句话的毛病是？",["搭配不当，笑声不能被“看见”","用词不够华丽","缺少标点符号","语序混乱"],0,"“看见”与“笑声”不搭配，应改为“听见”。"),
        q("sup3-p-43","writing",.primary,"writing.language",.challenge,"修改时发现一段内容与中心无关，应该？",["删去或压缩","保留并加以扩写","移到文章结尾","改写成人物对话"],0,"与中心无关的内容要舍得删。"),
        // 考场作文 · 材料立意与论证（初中 2）
        q("sup3-j-45","writing",.middle,"writing.argument",.foundation,"议论文的论点应当具备的特点是？",["正确、鲜明、有针对性","新奇、出人意料","含蓄、委婉","口语化、生活化"],0,"论点要经得起检验，还要说得清楚明白。"),
        q("sup3-j-46","writing",.middle,"writing.argument",.developing,"议论文中使用对比论证，作用是？",["突出事物差异，使观点更鲜明","增加文章的文采","延长文章篇幅","引出事实论据"],0,"两相对照，是非优劣自然显现。"),
        // 综合性学习 · 图表解读（小学 2 / 初中 2）
        q("sup3-p-44","integrated",.primary,"integrated.chart",.developing,"与扇形统计图相比，条形统计图更适合？",["比较不同类别数量的多少","表示各部分占整体的比例","表示随时间的变化趋势","表示地理位置"],0,"条形图便于横向比较数量的多少。"),
        q("sup3-p-45","integrated",.primary,"integrated.chart",.developing,"看图得出结论时，应该？",["依据图中数据，不添加图外信息","凭生活经验推测","只写最大的那个数据","按个人喜好表述"],0,"结论必须从图中的数据来，不能想当然。"),
        q("sup3-j-47","integrated",.middle,"integrated.chart",.developing,"统计图标题为“某校学生每周课外阅读时间”，结论应紧扣？",["标题所指的对象与数据的变化趋势","课外阅读的重要性","学校的硬件条件","考试制度的改革"],0,"结论要回答标题提出的问题，不能游移。"),
        q("sup3-j-48","integrated",.middle,"integrated.chart",.challenge,"图表与文字材料同时出现时，探究应当？",["图文互证，把数据变化与文字说明结合起来","只描述图表内容","只抄录文字材料","跳过图表不读"],0,"图文互补，结论才更完整可靠。"),
        // 综合性学习 · 标语·对联·徽标（小学 2 / 初中 2）
        q("sup3-p-46","integrated",.primary,"integrated.slogan",.developing,"为“校园读书节”拟标语，恰当的一项是？",["与经典同行，打好人生底色","读书节开始了","大家快来参加","学校举办活动"],0,"既点明读书主题，又写出意义，简洁有力。"),
        q("sup3-p-47","integrated",.primary,"integrated.slogan",.developing,"标语“小草微微笑，请你绕一绕”好在哪里？",["用拟人的方式委婉提示，亲切易被接受","说明小草真的会笑","语气强硬有力","字数比较多"],0,"把劝阻变成小草的请求，更容易被接受。"),
        q("sup3-j-49","integrated",.middle,"integrated.slogan",.developing,"为“垃圾分类”设计宣传语，最有效的是？",["垃圾分一分，校园美十分","请注意垃圾分类","垃圾需要分类","分类非常重要"],0,"押韵、对仗，并写出行动与结果的关联。"),
        q("sup3-j-50","integrated",.middle,"integrated.slogan",.challenge,"评价一则宣传语，首要标准是？",["主题突出、简洁易记、有号召力","上下句字数是否相等","是否使用对偶","是否出现品牌名称"],0,"宣传语要让人一听就懂、一记就牢。"),
        // 综合性学习 · 病句与标点（小学 2 / 初中 2）
        q("sup3-p-48","integrated",.primary,"integrated.language",.developing,"“他基本上把作业全部做完了”的病因是？",["前后矛盾，“基本上”与“全部”冲突","用词不当","成分残缺","语序不当"],0,"两个表示范围的词语互相抵触，删去其一。"),
        q("sup3-p-49","integrated",.primary,"integrated.language",.challenge,"“通过这次活动，使我明白了团结的重要。”这句的病因是？",["缺少主语，“通过”与“使”并用","搭配不当","重复啰嗦","语序不当"],0,"介词结构掩盖了主语，删去“通过”或“使”之一。"),
        q("sup3-j-51","integrated",.middle,"integrated.language",.challenge,"下列句子没有语病的是？",["经过讨论，大家一致同意这个方案","为了防止不再发生事故，学校加强了管理","他的写作水平明显改进了","我们要发扬和继承优良传统"],0,"B 否定不当，C 搭配不当，D 语序应为“继承和发扬”。"),
        q("sup3-j-52","integrated",.middle,"integrated.language",.developing,"“他的成绩不仅在班里名列前茅，而且在年级也很突出”属于？",["递进复句，语序合理","并列复句","转折复句","因果复句"],0,"“不仅……而且……”表递进，范围由小到大。"),
        // 综合性学习 · 口语交际与采访（小学 3）
        q("sup3-p-50","integrated",.primary,"integrated.oral",.developing,"采访中希望对方多谈一些，可以？",["追问“能具体说说吗”","连续提出是非法问题","打断对方的话","自己作长篇讲述"],0,"开放式追问能让对方展开细节。"),
        q("sup3-p-51","integrated",.primary,"integrated.oral",.developing,"与同学意见不同时，得体的表达是？",["先肯定对方的合理之处，再说明理由","直接否定对方的看法","沉默不予回应","请老师来评判对错"],0,"先接纳再补充，交流才能继续下去。"),
        q("sup3-p-52","integrated",.primary,"integrated.oral",.foundation,"在班会上发言，声音和语速应该？",["响亮清楚、语速适中","越快越好","越小越好","随意变化"],0,"让人听得清、跟得上，是发言的基本要求。"),
        // 综合性学习 · 新闻与标题（小学 3）
        q("sup3-p-53","integrated",.primary,"integrated.news",.developing,"新闻正文通常按什么结构安排？",["重要性递减的“倒金字塔”结构","严格的时间先后顺序","空间转换顺序","与事情发展相反的顺序"],0,"最重要的信息放在最前面，便于快速获取。"),
        q("sup3-p-54","integrated",.primary,"integrated.news",.developing,"拟写新闻标题最重要的要求是？",["准确概括最主要的事实","必须使用比喻","字数尽量多一些","抒发作者的感情"],0,"标题是新闻的眼睛，首先要求准确。"),
        q("sup3-p-55","integrated",.primary,"integrated.news",.challenge,"消息与通讯的主要区别是？",["消息更简短、更重时效，通讯更详细、更重描写","消息只能写人，通讯只能写事","消息必须用第一人称","两者没有区别"],0,"消息求快求简，通讯求深求细。"),
        // 综合性学习 · 活动方案与通知（小学 3）
        q("sup3-p-56","integrated",.primary,"integrated.activity",.developing,"设计“走进敬老院”活动，第一步应是？",["明确活动目的，并与对方联系确定时间","直接集合出发","先写好活动总结","先采购礼品"],0,"先定目的与安排，活动才有依据。"),
        q("sup3-p-57","integrated",.primary,"integrated.activity",.developing,"活动分工时主要应当考虑？",["按同学的兴趣与特长分配任务","让所有人做同一件事","全部交由老师承担","用抽签决定"],0,"各尽所长，合作才有效率。"),
        q("sup3-p-58","integrated",.primary,"integrated.activity",.foundation,"写活动通知时，语言应当？",["简明准确，要素齐全","生动抒情","多用修辞手法","篇幅越长越好"],0,"通知以求实为要，把要素说清楚即可。"),
        // 综合性学习 · 材料探究与跨文本（初中 2）
        q("sup3-j-53","integrated",.middle,"integrated.material",.developing,"多则材料探究的常用步骤是？",["分别概括—比较异同—提炼结论","只读懂第一则材料","把几则材料拼接成一段","只找其中相同的句子"],0,"先读懂各自，再作比较，最后才下结论。"),
        q("sup3-j-54","integrated",.middle,"integrated.material",.challenge,"从材料得出结论之后，还应注意？",["结论须有材料支撑，不作过度推断","尽量升华到人生哲理","加入个人情绪","结论写得越长越好"],0,"结论的范围不能超过材料所能支撑的范围。")
    ]
}
