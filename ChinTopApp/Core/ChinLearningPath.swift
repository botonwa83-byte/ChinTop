import Foundation

/// 学习路径：把知识点按学段分开、按「先学什么后学什么」排好队，并直接挂到练习题上。
///
/// 设计原则（针对"学生不知道从何学起"）：
/// 1. 小学高年级与初中各有一条独立路径，同一个知识点在两个学段的要求与题量不同，不再混在一起；
/// 2. 每一步都写清「这个知识点在题里长什么样」和「练完能拿下哪种题」，而不是讲方法名词；
/// 3. 每一步都直接带出练习题（按基础 → 提高 → 挑战递进），学完知识点立刻能做，不再先读方法论。
public struct ChinPathStep: Identifiable, Hashable {
    public let id: String
    public let grade: ChinGradeLevel
    /// 学段内的全局序号，从 1 开始；学生看到的就是"第几步"。
    public let order: Int
    public let knowledgePointID: String
    public let moduleID: String
    public let title: String
    /// 这个知识点在题目里长什么样（考什么）。
    public let brief: String
    /// 练完这一步能拿下哪种题（学到手的标志）。
    public let goal: String

    public var knowledgePoint: ChinKnowledgePoint? { ChinQuestionBank.knowledgePoint(id: knowledgePointID) }

    /// 该知识点在本学段的全部练习题，按 基础 → 提高 → 挑战 递进排列。
    public var questions: [ChinQuestion] {
        ChinQuestionBank
            .questions(moduleID: moduleID, grade: grade, knowledgePointID: knowledgePointID)
            .sorted { difficultyRank($0.difficulty) < difficultyRank($1.difficulty) }
    }

    public var questionCount: Int { questions.count }

    private func difficultyRank(_ d: ChinQuestionDifficulty) -> Int {
        switch d {
        case .foundation: return 0
        case .developing: return 1
        case .challenge: return 2
        }
    }
}

/// 学习阶段：把一条路径切成三关，让学生知道"我现在在第几关"。
public struct ChinPathStage: Identifiable, Hashable {
    public let id: String
    public let grade: ChinGradeLevel
    public let title: String
    public let subtitle: String
    public let icon: String
    public let steps: [ChinPathStep]

    public var questionCount: Int { steps.reduce(0) { $0 + $1.questionCount } }
}

public enum ChinLearningPath {

    /// 指定学段的完整学习路径（有序三关）。
    public static func stages(for grade: ChinGradeLevel) -> [ChinPathStage] {
        switch grade {
        case .primary: return primaryStages
        case .middle: return middleStages
        }
    }

    /// 指定学段按顺序铺平的所有步骤。
    public static func steps(for grade: ChinGradeLevel) -> [ChinPathStep] {
        stages(for: grade).flatMap(\.steps)
    }

    public static func step(knowledgePointID: String, grade: ChinGradeLevel) -> ChinPathStep? {
        steps(for: grade).first { $0.knowledgePointID == knowledgePointID }
    }

    /// 下一步该学什么：第一个还没练过的知识点；全部练过则回到第一个有待巩固错题的知识点。
    public static func nextStep(for grade: ChinGradeLevel, practiced: Set<String>, weakPoints: Set<String> = []) -> ChinPathStep? {
        let all = steps(for: grade)
        if let first = all.first(where: { !practiced.contains($0.knowledgePointID) }) { return first }
        return all.first { weakPoints.contains($0.knowledgePointID) } ?? all.first
    }

    // MARK: - 小学高年级路径（26 步）

    private static let primaryStages: [ChinPathStage] = build(
        grade: .primary,
        definitions: [
            ("primary.1", "第一关 · 把句子读通", "先保证字词句不出错，再谈理解", "textformat.abc", [
                ("integrated.language", "一句话哪里不通顺、标点该放哪", "改病句、补标点不丢分"),
                ("reading.evidence", "答案都在原文里，先学会找得到", "能按题目要求找全、抄准信息"),
                ("reading.character", "从一个动作、一句话看出人物特点", "人物形象题有话可说"),
                ("reading.environment", "景物描写在烘托什么心情", "答出环境描写的作用")
            ]),
            ("primary.2", "第二关 · 把文章读懂", "理清顺序、线索和词句的好处", "doc.text.magnifyingglass", [
                ("reading.structure", "文章先写什么后写什么、线索怎么串", "理清顺序与线索"),
                ("reading.title", "标题好在哪、能不能换成别的", "标题含义与作用题"),
                ("reading.language", "这个词、这句话为什么用得好", "赏析句子有角度可说"),
                ("reading.expository", "说明对象是什么、用了什么说明方法", "说明文三问拿稳"),
                ("reading.strategy", "带着问题读、边读边做标记", "读得快还答得准"),
                ("reading.inquiry", "联系生活谈看法，但答案要有依据", "开放题答得有理有据")
            ]),
            ("primary.3", "第三关 · 会用会写", "古诗、文言起步，再把作文写具体", "pencil.and.ruler", [
                ("poetry.imagery", "诗里写了哪些景物、画面什么样", "能用自己话描出画面"),
                ("poetry.word", "哪个字用得妙、妙在哪里", "炼字题说得清理由"),
                ("poetry.technique", "借景抒情、对比、动静结合这些手法", "认得出常见手法"),
                ("poetry.emotion", "诗人到底在表达什么感情", "感情概括不跑偏"),
                ("classical.word", "常见文言实词是什么意思", "读懂浅显的小古文"),
                ("classical.summary", "这篇短文讲了件什么事、人物怎样", "概括主要内容"),
                ("writing.topic", "题目要我写什么、选哪件事来写", "不跑题、有内容可写"),
                ("writing.detail", "把动作、语言、心理写具体", "作文不再空泛"),
                ("writing.structure", "开头点题、中间分层、结尾收束", "全文有骨架"),
                ("writing.language", "把自己的句子改得更准确生动", "会改自己的作文"),
                ("writing.application", "通知、留言、倡议书的格式", "应用文不丢格式分"),
                ("integrated.oral", "怎么说得清楚、问得得体", "口语交际题有话可说"),
                ("integrated.chart", "从图里读出变化和结论", "图表题说清趋势"),
                ("integrated.news", "一句话概括消息、给新闻拟标题", "概括与拟标题不超字"),
                ("integrated.slogan", "写标语、补对联、说清徽标含义", "语言运用题会写会评"),
                ("integrated.activity", "设计一次活动、写一份通知", "综合性学习题能落地")
            ])
        ]
    )

    // MARK: - 初中路径（26 步）

    private static let middleStages: [ChinPathStage] = build(
        grade: .middle,
        definitions: [
            ("middle.1", "第一关 · 语言与信息", "病句标点打底，长文里定位信息", "textformat.abc", [
                ("integrated.language", "病句类型、标点符号的规范用法", "语基选择题不丢分"),
                ("reading.evidence", "从长文里准确定位并整合信息", "筛选整合题拿满分"),
                ("reading.character", "从几件事里概括人物特点", "人物形象题答得全"),
                ("reading.structure", "线索是什么、段落有什么作用", "结构作用题有套路可依")
            ]),
            ("middle.2", "第二关 · 文体突破", "记叙、说明、议论三种文体逐个过", "doc.text.magnifyingglass", [
                ("reading.title", "标题的含义、作用与能否替换", "标题题答两层意思"),
                ("reading.language", "词语、句式、修辞的赏析角度", "赏析题有角度有依据"),
                ("reading.expository", "说明方法、说明顺序与语言准确", "说明文阅读稳定拿分"),
                ("reading.argumentative", "论点在哪、论据怎么支撑", "议论文三要素题"),
                ("reading.inquiry", "结合材料谈看法，观点加依据", "探究题答得站得住")
            ]),
            ("middle.3", "第三关 · 古诗文与写作", "文言实词虚词句式翻译，再加作文与材料题", "pencil.and.ruler", [
                ("poetry.imagery", "意象有哪些、画面什么特点", "描画面题有词可用"),
                ("poetry.word", "炼字炼句的表达效果", "炼字题说清妙处"),
                ("poetry.technique", "抒情方式、修辞与表现手法", "手法判断题认得准"),
                ("poetry.emotion", "诗歌的思想感情与主旨", "感情概括题不跑偏"),
                ("classical.word", "通假字、古今异义、词类活用", "实词解释题有底"),
                ("classical.function", "之乎者也等虚词的用法", "虚词辨析题"),
                ("classical.sentence", "判断句、倒装句、省略句", "句式判断题"),
                ("classical.translation", "直译为主、字字落实", "翻译题踩准得分点"),
                ("classical.summary", "文章内容概括与人物形象", "概括题答得完整"),
                ("classical.appreciation", "写法特点与主旨理解", "写法主旨题"),
                ("writing.topic", "审题抓关键词、选有张力的事", "作文不跑题"),
                ("writing.detail", "细节描写让文章有画面", "记叙文写得具体"),
                ("writing.structure", "开头入题、层次推进、结尾升华", "全文有结构"),
                ("writing.application", "书信、通知、倡议书等应用文", "应用文格式不失分"),
                ("writing.argument", "从材料里提炼观点并论证", "材料作文立得住"),
                ("integrated.chart", "图表信息转述与结论归纳", "图表题说清趋势"),
                ("integrated.slogan", "标语、对联、徽标的创作与赏析", "语言运用题会写会评"),
                ("integrated.material", "多材料探究与跨文本比较", "材料探究题有思路")
            ])
        ]
    )

    // MARK: - 构造

    private static func build(
        grade: ChinGradeLevel,
        definitions: [(id: String, title: String, subtitle: String, icon: String, items: [(point: String, brief: String, goal: String)])]
    ) -> [ChinPathStage] {
        var order = 1
        return definitions.map { def in
            let steps = def.items.compactMap { item -> ChinPathStep? in
                guard let point = ChinQuestionBank.knowledgePoint(id: item.point) else { return nil }
                defer { order += 1 }
                return ChinPathStep(
                    id: "\(grade.rawValue)-\(point.id)",
                    grade: grade,
                    order: order,
                    knowledgePointID: point.id,
                    moduleID: point.moduleID,
                    title: point.title,
                    brief: item.brief,
                    goal: item.goal
                )
            }
            return ChinPathStage(id: def.id, grade: grade, title: def.title, subtitle: def.subtitle, icon: def.icon, steps: steps)
        }
    }
}
