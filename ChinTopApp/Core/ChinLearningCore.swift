import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum ChinGradeLevel: String, CaseIterable, Codable, Identifiable {
    case primary
    case middle

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .primary: return "小学高年级"
        case .middle: return "初中"
        }
    }

    public var subtitle: String {
        switch self {
        case .primary: return "先学会找依据，再把话说完整"
        case .middle: return "从证据到观点，稳定拿到过程分"
        }
    }
}

public struct ChinCapability: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let detail: String
    public let icon: String
    public let colorName: String

    public init(id: String, title: String, subtitle: String, detail: String, icon: String, colorName: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.icon = icon
        self.colorName = colorName
    }

    public static let all: [ChinCapability] = [
        ChinCapability(
            id: "evidence",
            title: "证据提取",
            subtitle: "从文字里找到能支持观点的依据",
            detail: "学会圈出动作、语言、数据和关键词，不再只凭感觉答题。",
            icon: "scope",
            colorName: "blue"
        ),
        ChinCapability(
            id: "reasoning",
            title: "结构推理",
            subtitle: "把零散信息组织成清晰的因果链",
            detail: "知道先说什么、后说什么，能解释“为什么这样判断”。",
            icon: "point.3.connected.trianglepath.dotted",
            colorName: "orange"
        ),
        ChinCapability(
            id: "expression",
            title: "规范表达",
            subtitle: "用完整、准确、有层次的语言作答",
            detail: "把答案写成阅卷人看得懂、找得到采分点的句子。",
            icon: "text.alignleft",
            colorName: "green"
        ),
        ChinCapability(
            id: "creation",
            title: "创意写作",
            subtitle: "把观察、感受和想象写成自己的作品",
            detail: "用细节、结构和有画面的语言表达真实想法。",
            icon: "wand.and.stars",
            colorName: "pink"
        ),
        ChinCapability(
            id: "reflection",
            title: "复盘迁移",
            subtitle: "看懂错因，把一次练习变成下一次进步",
            detail: "记录卡在哪里、下一步怎么改，把方法带到新题和生活中。",
            icon: "arrow.triangle.2.circlepath",
            colorName: "purple"
        )
    ]

    public static func capability(for id: String) -> ChinCapability {
        all.first(where: { $0.id == id }) ?? all[0]
    }

    /// 表驱动映射：优先按知识点 ID 归类，旧数据没有知识点 ID 时回退到中文关键词匹配。
    public static func capabilityID(knowledgePointID: String?, moduleID: String, skill: String) -> String {
        if let knowledgePointID, let mapped = knowledgePointCapability[knowledgePointID] {
            return mapped
        }
        return capabilityID(moduleID: moduleID, skill: skill)
    }

    private static let knowledgePointCapability: [String: String] = [
        "reading.character": "evidence",
        "reading.evidence": "evidence",
        "reading.environment": "evidence",
        "reading.inquiry": "evidence",
        "reading.title": "reasoning",
        "reading.structure": "reasoning",
        "reading.expository": "reasoning",
        "reading.argumentative": "reasoning",
        "reading.strategy": "reasoning",
        "reading.language": "expression",
        "classical.word": "reasoning",
        "classical.function": "reasoning",
        "classical.sentence": "reasoning",
        "classical.summary": "reasoning",
        "classical.appreciation": "reasoning",
        "classical.translation": "expression",
        "poetry.imagery": "expression",
        "poetry.word": "expression",
        "poetry.technique": "expression",
        "poetry.emotion": "expression",
        "writing.topic": "creation",
        "writing.detail": "creation",
        "writing.structure": "creation",
        "writing.language": "expression",
        "writing.application": "expression",
        "writing.argument": "expression",
        "integrated.chart": "reasoning",
        "integrated.news": "reasoning",
        "integrated.activity": "reasoning",
        "integrated.material": "reasoning",
        "integrated.oral": "expression",
        "integrated.slogan": "expression",
        "integrated.language": "expression"
    ]

    public static func capabilityID(moduleID: String, skill: String) -> String {
        switch moduleID {
        case "classical":
            return "reasoning"
        case "poetry":
            return "expression"
        case "writing":
            return "creation"
        case "integrated":
            let expressionSkills = ["宣传", "口语", "病句", "标点", "对联", "演讲", "表达"]
            return expressionSkills.contains(where: skill.contains) ? "expression" : "reasoning"
        case "reading":
            let expressionSkills = ["句子", "赏析", "语言"]
            if expressionSkills.contains(where: skill.contains) {
                return "expression"
            }
            let reasoningSkills = ["标题", "结构", "顺序", "线索", "论证", "论点", "阅读策略", "说明方法", "说明顺序", "伏笔"]
            return reasoningSkills.contains(where: skill.contains) ? "reasoning" : "evidence"
        default:
            return "reasoning"
        }
    }
}

public struct ChinMethodCard: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let capabilityID: String
    public let summary: String
    public let steps: [String]
    public let example: String
    public let practicePrompt: String
    public let taskID: String?

    public init(
        id: String,
        title: String,
        capabilityID: String,
        summary: String,
        steps: [String],
        example: String,
        practicePrompt: String,
        taskID: String?
    ) {
        self.id = id
        self.title = title
        self.capabilityID = capabilityID
        self.summary = summary
        self.steps = steps
        self.example = example
        self.practicePrompt = practicePrompt
        self.taskID = taskID
    }
}

public enum ChinMethodCardCatalog {
    public static let all: [ChinMethodCard] = [
        ChinMethodCard(
            id: "evidence-action-quality",
            title: "动作是人物品质的证据",
            capabilityID: "evidence",
            summary: "人物做了什么，往往比“他很善良”更能证明人物形象。",
            steps: ["圈出人物的具体动作", "把动作翻译成品质", "补上动作带来的结果"],
            example: "他把唯一的雨伞递给同学，自己跑进雨幕，表现出乐于助人的品质。",
            practicePrompt: "遇到人物形象题，先问：他做了什么？",
            taskID: "reading-evidence-chain"
        ),
        ChinMethodCard(
            id: "evidence-data-boundary",
            title: "数据结论要有边界",
            capabilityID: "reasoning",
            summary: "图表能支持差异和趋势，但不能自动证明唯一原因。",
            steps: ["说清比较对象", "准确描述变化或差异", "用“本次调查”限定结论"],
            example: "本次调查中，阅读时间较长的同学平均成绩更高，但不能据此断定阅读是唯一原因。",
            practicePrompt: "看到数据时，先检查自己的结论有没有夸大。",
            taskID: "integrated-data-conclusion"
        ),
        ChinMethodCard(
            id: "reasoning-title-two-layers",
            title: "标题要读两层",
            capabilityID: "reasoning",
            summary: "先解释字面意思，再联系事件、人物和主题读出深层含义。",
            steps: ["解释关键词的字面义", "联系文章中的事件", "说出标题寄托的情感或主题"],
            example: "“迟到的掌声”表面指演出后的掌声，深层暗示主人公得到认可来得很晚。",
            practicePrompt: "标题题不要只写“点明中心”，要把中心说具体。",
            taskID: "reading-title-two-layers"
        ),
        ChinMethodCard(
            id: "reasoning-context-replacement",
            title: "文言词义用语境验证",
            capabilityID: "reasoning",
            summary: "同一个古汉字可能有多个意思，搭配和上下文才是判断依据。",
            steps: ["看词语所在短语", "观察前后搭配关系", "用现代词替换并通读验证"],
            example: "“见贤思齐”的“齐”是看齐，因为“见贤”之后的“思”指向向贤者学习。",
            practicePrompt: "解释实词时，不要脱离句子背词典义。",
            taskID: "classical-context-meaning"
        ),
        ChinMethodCard(
            id: "reasoning-answer-chain",
            title: "答案按因果链组织",
            capabilityID: "expression",
            summary: "把“观点—依据—结果”连起来，答案才有完整的推理过程。",
            steps: ["先写判断", "补充文本证据", "说明证据为什么支持判断"],
            example: "他体贴，因为把最后一块年糕留给奶奶，说明他愿意把别人的需要放在前面。",
            practicePrompt: "检查答案：别人能不能看懂我为什么这样判断？",
            taskID: "expression-answer-upgrade"
        ),
        ChinMethodCard(
            id: "expression-three-parts",
            title: "观点、证据、作用",
            capabilityID: "expression",
            summary: "语文主观题的稳定句式：先判断，再引用，再解释作用。",
            steps: ["观点先行，回答“是什么”", "证据跟上，回答“从哪里看出”", "作用收束，回答“说明了什么”"],
            example: "“落红”运用借物抒情，写落花化泥护花，表现诗人离开岗位后仍愿奉献的情怀。",
            practicePrompt: "写完答案后，用“因为……所以……”检查是否闭环。",
            taskID: "expression-answer-upgrade"
        ),
        ChinMethodCard(
            id: "expression-poetry-picture",
            title: "诗句画面要有动作",
            capabilityID: "expression",
            summary: "不要只罗列意象，要把景物组织成读者能看见的场景。",
            steps: ["列出意象", "补上动作和空间关系", "用氛围词收束画面"],
            example: "枯藤缠绕老树，黄昏时乌鸦停在枝头，画面凄清，流露出羁旅孤寂。",
            practicePrompt: "画面题至少写出景物、动作和氛围。",
            taskID: "poetry-image-and-feeling"
        ),
        ChinMethodCard(
            id: "creation-sensory-detail",
            title: "把情绪变成细节",
            capabilityID: "creation",
            summary: "删掉“我很紧张”这类抽象判断，让读者从身体和动作感受到情绪。",
            steps: ["删掉“我很……”", "加入身体感受", "补一个可观察的动作或声音"],
            example: "我盯着台下黑压压的人群，手心渗出汗，稿纸边角被我捏出折痕。",
            practicePrompt: "写情绪时，优先选择一个能被看见或听见的细节。",
            taskID: "writing-sensory-detail"
        ),
        ChinMethodCard(
            id: "creation-opening-memory",
            title: "用感官打开回忆",
            capabilityID: "creation",
            summary: "气味、声音和触感可以自然触发回忆，比直接说“我想起了”更有画面。",
            steps: ["选择一个现场感官", "写出它带来的变化", "让回忆自然接入事件"],
            example: "风把院里的桂花香送进来，我忽然想起那年秋天和奶奶一起等人的下午。",
            practicePrompt: "开头先给读者一个可感的瞬间，再进入故事。",
            taskID: "writing-sensory-detail"
        ),
        ChinMethodCard(
            id: "reflection-mistake-card",
            title: "错题复盘三句话",
            capabilityID: "reflection",
            summary: "复盘不是抄答案，而是找出下一次可以执行的动作。",
            steps: ["我具体错在哪", "正确依据在文本哪里", "下一次我先做什么"],
            example: "我把感受当成了文本意思；正确依据是人物动作；下次先圈证据，再写观点。",
            practicePrompt: "把“粗心”改写成一个具体、可改变的错误动作。",
            taskID: "mistake-to-method"
        ),
        ChinMethodCard(
            id: "reflection-retry-transfer",
            title: "复盘后换一道题",
            capabilityID: "reflection",
            summary: "真正掌握方法，不是记住这一题，而是能迁移到相似的新题。",
            steps: ["说清原题的关键方法", "找一道同技能新题", "比较两题证据是否同类"],
            example: "原题用动作判断人物品质，新题仍先找动作，再判断品质，最后补结果。",
            practicePrompt: "复盘结束后，用同一个方法完成一题新任务。",
            taskID: "mistake-to-method"
        )
    ]

    public static func search(query: String, capabilityID: String? = nil) -> [ChinMethodCard] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return all.filter { card in
            let matchesCapability = capabilityID == nil || card.capabilityID == capabilityID
            guard matchesCapability else { return false }
            guard !trimmed.isEmpty else { return true }
            let searchableText = ([card.title, card.summary, card.example, card.practicePrompt] + card.steps).joined(separator: " ")
            return searchableText.localizedCaseInsensitiveContains(trimmed)
        }
    }

    public static func card(forTaskID taskID: String) -> ChinMethodCard? {
        all.first(where: { $0.taskID == taskID })
    }
}

public struct ChinDailyTask: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let moduleID: String
    public let capabilityID: String
    public let method: String
    public let challenge: String
    public let example: String
    public let steps: [String]
    public let prompt: String
    public let estimatedMinutes: Int

    public init(
        id: String,
        title: String,
        subtitle: String,
        moduleID: String,
        capabilityID: String,
        method: String,
        challenge: String,
        example: String,
        steps: [String],
        prompt: String,
        estimatedMinutes: Int
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.moduleID = moduleID
        self.capabilityID = capabilityID
        self.method = method
        self.challenge = challenge
        self.example = example
        self.steps = steps
        self.prompt = prompt
        self.estimatedMinutes = estimatedMinutes
    }
}

public enum ChinDailyTaskCatalog {
    public static let all: [ChinDailyTask] = [
        ChinDailyTask(
            id: "reading-evidence-chain",
            title: "把证据说完整",
            subtitle: "现代文阅读 · 人物形象",
            moduleID: "reading",
            capabilityID: "evidence",
            method: "证据三步法：找动作 → 说品质 → 补结果",
            challenge: "雨停了，屋檐还在滴水。小明把唯一的雨伞递给同学，自己跑进了雨幕。请用一句完整的话说明小明的品质。",
            example: "小明把雨伞给同学、自己淋雨的动作，表现了他乐于助人的品质。",
            steps: ["圈出人物做了什么", "把动作翻译成品质", "用“因为……所以……”补足证据"],
            prompt: "你的答案",
            estimatedMinutes: 8
        ),
        ChinDailyTask(
            id: "classical-context-meaning",
            title: "让古文字回到语境",
            subtitle: "文言文解码 · 实词",
            moduleID: "classical",
            capabilityID: "reasoning",
            method: "语境替换法：先看搭配，再用现代词替换验证",
            challenge: "“见贤思齐焉”中的“齐”是什么意思？请写出词义，并说明你从哪里判断。",
            example: "“齐”是看齐、向他看齐。前文有“见贤”，后文是“思”，说明看到贤人就想向他学习。",
            steps: ["找出词语所在短语", "观察它和谁搭配", "用完整句子解释判断依据"],
            prompt: "你的解释",
            estimatedMinutes: 10
        ),
        ChinDailyTask(
            id: "poetry-image-and-feeling",
            title: "让诗句成为画面",
            subtitle: "古诗词鉴赏 · 画面描绘",
            moduleID: "poetry",
            capabilityID: "expression",
            method: "意象组合法：景物 + 动作 + 氛围 + 情感",
            challenge: "“枯藤老树昏鸦”描绘了怎样的画面？请用一到两句话写出画面和氛围。",
            example: "枯藤缠绕着老树，黄昏时乌鸦停在枝头，画面凄清，流露出羁旅中的孤寂。",
            steps: ["列出诗句中的意象", "补上动作和空间关系", "用一个氛围词收束画面"],
            prompt: "你的画面",
            estimatedMinutes: 10
        ),
        ChinDailyTask(
            id: "writing-sensory-detail",
            title: "把情绪写成细节",
            subtitle: "考场作文升格 · 细节描写",
            moduleID: "writing",
            capabilityID: "creation",
            method: "抽象情绪变具体：身体感受 + 动作 + 周围声音",
            challenge: "把“我很紧张”改写成一句读者能看见、听见或感受到的细节。",
            example: "我盯着台下黑压压的人群，手心渗出汗，稿纸的边角被我捏出了一道折痕。",
            steps: ["删掉“我很……”", "选择一个身体感受", "加一个可观察的动作或声音"],
            prompt: "你的改写",
            estimatedMinutes: 8
        ),
        ChinDailyTask(
            id: "integrated-data-conclusion",
            title: "从数据得出稳妥结论",
            subtitle: "综合性学习 · 图表解读",
            moduleID: "integrated",
            capabilityID: "reasoning",
            method: "图表四问：对象、变化、差异、边界",
            challenge: "调查显示：每天阅读20分钟的同学平均分88分，阅读不足10分钟的同学平均分76分。请写出不夸大的结论。",
            example: "在本次调查中，阅读时间较长的同学平均成绩更高，但这不等于阅读时间是成绩的唯一原因。",
            steps: ["说清比较的对象", "说出数据呈现的差异", "补上“本次调查”这样的边界"],
            prompt: "你的结论",
            estimatedMinutes: 10
        ),
        ChinDailyTask(
            id: "mistake-to-method",
            title: "把错题变成方法",
            subtitle: "学习复盘 · 错因迁移",
            moduleID: "reading",
            capabilityID: "reflection",
            method: "错因复盘卡：我错在哪 → 正确依据 → 下次动作",
            challenge: "回想最近一道做错的语文题，用三句话写清：错因、正确依据、下一次准备怎么做。",
            example: "我把自己的感受当成了文本意思。正确依据是人物的动作细节。下次先圈证据，再写观点。",
            steps: ["描述具体错因", "补上能验证的依据", "写一个下一次可执行的动作"],
            prompt: "你的复盘",
            estimatedMinutes: 8
        ),
        ChinDailyTask(
            id: "reading-title-two-layers",
            title: "标题要读两层",
            subtitle: "现代文阅读 · 标题含义",
            moduleID: "reading",
            capabilityID: "reasoning",
            method: "表层 + 深层：先解释字面，再联系人物和主题",
            challenge: "标题“迟到的掌声”既指演出结束后的掌声，也可能暗示什么？",
            example: "表层是演出后的掌声，深层是主人公得到认可来得很晚，表现等待和成长。",
            steps: ["解释标题中的关键词", "联系文章事件", "补上标题寄托的情感"],
            prompt: "你的两层解释",
            estimatedMinutes: 8
        ),
        ChinDailyTask(
            id: "expression-answer-upgrade",
            title: "让答案更像答案",
            subtitle: "规范表达 · 采分点组织",
            moduleID: "integrated",
            capabilityID: "expression",
            method: "观点 + 证据 + 作用：三段式组织句",
            challenge: "把“他很善良”扩写成有证据的完整答案，材料是“他把最后一块年糕夹给奶奶，自己只喝粥”。",
            example: "他体贴、愿意付出，因为他把最后一块年糕留给奶奶，自己的需要放在了后面。",
            steps: ["先写人物或内容判断", "补上原文行为", "用“表现出/说明”收束"],
            prompt: "你的完整答案",
            estimatedMinutes: 8
        )
    ]

    public static func task(
        for date: Date = .now,
        grade: ChinGradeLevel = .middle,
        calendar: Calendar = .current
    ) -> ChinDailyTask {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let year = calendar.component(.year, from: date)
        let index = abs(year * 367 + day) % all.count
        let base = all[index]
        guard grade == .primary else { return base }
        return ChinDailyTask(
            id: base.id,
            title: base.title,
            subtitle: base.subtitle,
            moduleID: base.moduleID,
            capabilityID: base.capabilityID,
            method: "\(base.method)（先说后写）",
            challenge: "\(base.challenge) 小提示：先列出两个关键词，再组成句子。",
            example: base.example,
            steps: base.steps,
            prompt: base.prompt,
            estimatedMinutes: base.estimatedMinutes
        )
    }
}

public struct ChinPortfolioEntry: Identifiable, Codable, Hashable {
    public let id: String
    public let taskID: String
    public let title: String
    public let moduleID: String
    public let capabilityID: String
    public let prompt: String
    public let response: String
    public let reflection: String
    public let checklist: [String: Bool]
    public let createdAt: Date

    public var checklistProgress: Double {
        guard !checklist.isEmpty else { return 0 }
        return Double(checklist.values.filter { $0 }.count) / Double(checklist.count)
    }
}

public struct ChinMistakeRecord: Identifiable, Codable, Hashable {
    public let id: String
    public let questionID: String
    public let moduleID: String
    public var capabilityID: String?
    public var gradeID: String?
    public var knowledgePointID: String?
    public var difficulty: String?
    public let skill: String
    public let prompt: String
    public var selectedAnswer: String
    public let correctAnswer: String
    public let explanation: String
    public var reviewCount: Int
    public var isResolved: Bool
    public var lastAttemptAt: Date

    public init(
        questionID: String,
        moduleID: String,
        capabilityID: String? = nil,
        gradeID: String? = nil,
        knowledgePointID: String? = nil,
        difficulty: String? = nil,
        skill: String,
        prompt: String,
        selectedAnswer: String,
        correctAnswer: String,
        explanation: String,
        reviewCount: Int = 0,
        isResolved: Bool = false,
        lastAttemptAt: Date
    ) {
        self.id = questionID
        self.questionID = questionID
        self.moduleID = moduleID
        self.capabilityID = capabilityID
        self.gradeID = gradeID
        self.knowledgePointID = knowledgePointID
        self.difficulty = difficulty
        self.skill = skill
        self.prompt = prompt
        self.selectedAnswer = selectedAnswer
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.reviewCount = reviewCount
        self.isResolved = isResolved
        self.lastAttemptAt = lastAttemptAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case questionID
        case moduleID
        case capabilityID
        case gradeID
        case knowledgePointID
        case difficulty
        case skill
        case prompt
        case selectedAnswer
        case correctAnswer
        case explanation
        case reviewCount
        case isResolved
        case lastAttemptAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedQuestionID = try container.decodeIfPresent(String.self, forKey: .questionID)
            ?? container.decode(String.self, forKey: .id)
        self.init(
            questionID: decodedQuestionID,
            moduleID: try container.decodeIfPresent(String.self, forKey: .moduleID) ?? "",
            capabilityID: try container.decodeIfPresent(String.self, forKey: .capabilityID),
            gradeID: try container.decodeIfPresent(String.self, forKey: .gradeID),
            knowledgePointID: try container.decodeIfPresent(String.self, forKey: .knowledgePointID),
            difficulty: try container.decodeIfPresent(String.self, forKey: .difficulty),
            skill: try container.decodeIfPresent(String.self, forKey: .skill) ?? "",
            prompt: try container.decodeIfPresent(String.self, forKey: .prompt) ?? "",
            selectedAnswer: try container.decodeIfPresent(String.self, forKey: .selectedAnswer) ?? "",
            correctAnswer: try container.decodeIfPresent(String.self, forKey: .correctAnswer) ?? "",
            explanation: try container.decodeIfPresent(String.self, forKey: .explanation) ?? "",
            reviewCount: try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0,
            isResolved: try container.decodeIfPresent(Bool.self, forKey: .isResolved) ?? false,
            lastAttemptAt: try container.decodeIfPresent(Date.self, forKey: .lastAttemptAt) ?? Date(timeIntervalSince1970: 0)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(questionID, forKey: .questionID)
        try container.encode(moduleID, forKey: .moduleID)
        try container.encodeIfPresent(capabilityID, forKey: .capabilityID)
        try container.encodeIfPresent(gradeID, forKey: .gradeID)
        try container.encodeIfPresent(knowledgePointID, forKey: .knowledgePointID)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
        try container.encode(skill, forKey: .skill)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(selectedAnswer, forKey: .selectedAnswer)
        try container.encode(correctAnswer, forKey: .correctAnswer)
        try container.encode(explanation, forKey: .explanation)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encode(isResolved, forKey: .isResolved)
        try container.encode(lastAttemptAt, forKey: .lastAttemptAt)
    }
}

public struct ChinLearningSnapshot: Codable, Equatable {
    public var gradeID: String
    public var completedTaskIDs: [String]
    public var completedTaskKeys: [String]
    public var portfolio: [ChinPortfolioEntry]
    public var mistakes: [ChinMistakeRecord]
    public var practiceCount: Int
    public var correctCount: Int
    public var activityDates: [String]
    /// 知识点 ID → 已练题数。用于在学习路径上标出"学到第几步、哪一步练过"。
    /// 新增字段：旧存档没有此键时按空解码，不影响老用户数据。
    public var knowledgePointProgress: [String: Int]

    public init(
        gradeID: String = ChinGradeLevel.middle.rawValue,
        completedTaskIDs: [String] = [],
        completedTaskKeys: [String] = [],
        portfolio: [ChinPortfolioEntry] = [],
        mistakes: [ChinMistakeRecord] = [],
        practiceCount: Int = 0,
        correctCount: Int = 0,
        activityDates: [String] = [],
        knowledgePointProgress: [String: Int] = [:]
    ) {
        self.gradeID = gradeID
        self.completedTaskIDs = completedTaskIDs
        self.completedTaskKeys = completedTaskKeys
        self.portfolio = portfolio
        self.mistakes = mistakes
        self.practiceCount = practiceCount
        self.correctCount = correctCount
        self.activityDates = activityDates
        self.knowledgePointProgress = knowledgePointProgress
    }

    private enum CodingKeys: String, CodingKey {
        case gradeID
        case completedTaskIDs
        case completedTaskKeys
        case portfolio
        case mistakes
        case practiceCount
        case correctCount
        case activityDates
        case knowledgePointProgress
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            gradeID: try container.decodeIfPresent(String.self, forKey: .gradeID) ?? ChinGradeLevel.middle.rawValue,
            completedTaskIDs: try container.decodeIfPresent([String].self, forKey: .completedTaskIDs) ?? [],
            completedTaskKeys: try container.decodeIfPresent([String].self, forKey: .completedTaskKeys) ?? [],
            portfolio: try container.decodeIfPresent([ChinPortfolioEntry].self, forKey: .portfolio) ?? [],
            mistakes: try container.decodeIfPresent([ChinMistakeRecord].self, forKey: .mistakes) ?? [],
            practiceCount: try container.decodeIfPresent(Int.self, forKey: .practiceCount) ?? 0,
            correctCount: try container.decodeIfPresent(Int.self, forKey: .correctCount) ?? 0,
            activityDates: try container.decodeIfPresent([String].self, forKey: .activityDates) ?? [],
            knowledgePointProgress: try container.decodeIfPresent([String: Int].self, forKey: .knowledgePointProgress) ?? [:]
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gradeID, forKey: .gradeID)
        try container.encode(completedTaskIDs, forKey: .completedTaskIDs)
        try container.encode(completedTaskKeys, forKey: .completedTaskKeys)
        try container.encode(portfolio, forKey: .portfolio)
        try container.encode(mistakes, forKey: .mistakes)
        try container.encode(practiceCount, forKey: .practiceCount)
        try container.encode(correctCount, forKey: .correctCount)
        try container.encode(activityDates, forKey: .activityDates)
        try container.encode(knowledgePointProgress, forKey: .knowledgePointProgress)
    }

    public var accuracy: Double {
        guard practiceCount > 0 else { return 0 }
        return Double(correctCount) / Double(practiceCount)
    }

    public var unresolvedMistakes: [ChinMistakeRecord] {
        mistakes.filter { !$0.isResolved }
    }

    public func currentStreak(now: Date = .now, calendar: Calendar = .current) -> Int {
        let activeDays = Set(activityDates)
        var day = calendar.startOfDay(for: now)
        let todayKey = Self.dayKey(for: day, calendar: calendar)
        if !activeDays.contains(todayKey) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var result = 0
        while activeDays.contains(Self.dayKey(for: day, calendar: calendar)) {
            result += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return result
    }

    public mutating func setGrade(_ grade: ChinGradeLevel) {
        gradeID = grade.rawValue
    }

    public mutating func completeTask(_ taskID: String, date: Date, calendar: Calendar = .current) {
        if !completedTaskIDs.contains(taskID) {
            completedTaskIDs.append(taskID)
        }
        let completionKey = Self.completedTaskKey(for: taskID, date: date, calendar: calendar)
        if !completedTaskKeys.contains(completionKey) {
            completedTaskKeys.append(completionKey)
        }
        recordActivity(on: date, calendar: calendar)
    }

    public func isTaskCompleted(
        _ taskID: String,
        on date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        let completionKey = Self.completedTaskKey(for: taskID, date: date, calendar: calendar)
        if completedTaskKeys.contains(completionKey) {
            return true
        }
        return portfolio.contains {
            $0.taskID == taskID && calendar.isDate($0.createdAt, inSameDayAs: date)
        }
    }

    public mutating func recordPractice(
        questionID: String,
        moduleID: String,
        capabilityID: String? = nil,
        gradeID: String? = nil,
        knowledgePointID: String? = nil,
        difficulty: String? = nil,
        skill: String,
        prompt: String,
        selectedAnswer: String,
        correctAnswer: String,
        explanation: String,
        isCorrect: Bool,
        date: Date,
        calendar: Calendar = .current
    ) {
        practiceCount += 1
        if isCorrect {
            correctCount += 1
        }
        if let knowledgePointID {
            knowledgePointProgress[knowledgePointID, default: 0] += 1
        }
        recordActivity(on: date, calendar: calendar)

        if let index = mistakes.firstIndex(where: { $0.questionID == questionID }) {
            mistakes[index].selectedAnswer = selectedAnswer
            if let capabilityID {
                mistakes[index].capabilityID = capabilityID
            }
            if let gradeID {
                mistakes[index].gradeID = gradeID
            }
            if let knowledgePointID {
                mistakes[index].knowledgePointID = knowledgePointID
            }
            if let difficulty {
                mistakes[index].difficulty = difficulty
            }
            mistakes[index].lastAttemptAt = date
            if isCorrect {
                mistakes[index].isResolved = true
                mistakes[index].reviewCount += 1
            } else {
                mistakes[index].isResolved = false
            }
        } else if !isCorrect {
            mistakes.append(
                ChinMistakeRecord(
                    questionID: questionID,
                    moduleID: moduleID,
                    capabilityID: capabilityID,
                    gradeID: gradeID,
                    knowledgePointID: knowledgePointID,
                    difficulty: difficulty,
                    skill: skill,
                    prompt: prompt,
                    selectedAnswer: selectedAnswer,
                    correctAnswer: correctAnswer,
                    explanation: explanation,
                    lastAttemptAt: date
                )
            )
        }
    }

    public mutating func savePortfolio(
        task: ChinDailyTask,
        response: String,
        reflection: String,
        checklist: [String: Bool],
        date: Date,
        calendar: Calendar = .current
    ) {
        let entryID = "\(task.id)-\(Self.dayKey(for: date, calendar: calendar))"
        let entry = ChinPortfolioEntry(
            id: entryID,
            taskID: task.id,
            title: task.title,
            moduleID: task.moduleID,
            capabilityID: task.capabilityID,
            prompt: task.challenge,
            response: response,
            reflection: reflection,
            checklist: checklist,
            createdAt: date
        )
        if let index = portfolio.firstIndex(where: { $0.id == entryID }) {
            portfolio[index] = entry
        } else {
            portfolio.insert(entry, at: 0)
        }
        completeTask(task.id, date: date, calendar: calendar)
    }

    private mutating func recordActivity(on date: Date, calendar: Calendar) {
        let key = Self.dayKey(for: date, calendar: calendar)
        if !activityDates.contains(key) {
            activityDates.append(key)
            activityDates.sort()
        }
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private static func completedTaskKey(
        for taskID: String,
        date: Date,
        calendar: Calendar
    ) -> String {
        "\(dayKey(for: date, calendar: calendar))|\(taskID)"
    }

    public func learningReport(
        now: Date = .now,
        calendar: Calendar = .current
    ) -> ChinLearningReport {
        ChinLearningReport.make(from: self, now: now, calendar: calendar)
    }
}

public enum ChinCapabilityStatus: String, Codable, Hashable {
    case notStarted
    case building
    case needsReview

    public var title: String {
        switch self {
        case .notStarted: return "尚未开始"
        case .building: return "已有作品"
        case .needsReview: return "需要复盘"
        }
    }
}

public struct ChinCapabilityEvidence: Identifiable, Codable, Hashable {
    public let capabilityID: String
    public let title: String
    public let portfolioCount: Int
    public let taskCount: Int
    public let status: ChinCapabilityStatus
    public let nextAction: String

    public var id: String { capabilityID }
}

public struct ChinLearningReport: Codable, Hashable {
    public let practiceCount: Int
    public let correctCount: Int
    public let portfolioCount: Int
    public let unresolvedMistakeCount: Int
    public let activeDayCount: Int
    public let streak: Int
    public let capabilities: [ChinCapabilityEvidence]
    public let focusCapabilityID: String?
    public let headline: String

    public var accuracyPercent: Int? {
        guard practiceCount > 0 else { return nil }
        return Int((Double(correctCount) / Double(practiceCount) * 100).rounded())
    }

    public var focusCapability: ChinCapability? {
        guard let focusCapabilityID else { return nil }
        return ChinCapability.capability(for: focusCapabilityID)
    }

    public static func make(
        from snapshot: ChinLearningSnapshot,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> ChinLearningReport {
        let tasks = ChinDailyTaskCatalog.all
        let reviewCapabilityIDs = Set(
            snapshot.unresolvedMistakes.compactMap { mistake in
                mistake.capabilityID ?? tasks.first(where: { $0.moduleID == mistake.moduleID })?.capabilityID
            }
        )

        let evidence = ChinCapability.all.map { capability in
            let capabilityTasks = tasks.filter { $0.capabilityID == capability.id }
            let portfolioCount = snapshot.portfolio.filter { $0.capabilityID == capability.id }.count
            let hasReview = reviewCapabilityIDs.contains(capability.id)
            let status: ChinCapabilityStatus
            let nextAction: String

            if hasReview {
                status = .needsReview
                nextAction = "先复盘一张错题，再完成一个同类任务"
            } else if portfolioCount > 0 {
                status = .building
                nextAction = "再完成 1 份作品，形成连续练习"
            } else {
                status = .notStarted
                nextAction = "从一个短任务开始，留下第一份作品"
            }

            return ChinCapabilityEvidence(
                capabilityID: capability.id,
                title: capability.title,
                portfolioCount: portfolioCount,
                taskCount: capabilityTasks.count,
                status: status,
                nextAction: nextAction
            )
        }

        let focusID: String?
        let headline: String
        if let review = evidence.first(where: { $0.status == .needsReview }) {
            focusID = review.capabilityID
            headline = "先处理 \(snapshot.unresolvedMistakes.count) 张待复盘错题"
        } else if !snapshot.portfolio.isEmpty {
            focusID = evidence.first(where: { $0.status == .notStarted })?.capabilityID
            headline = "你已经留下 \(snapshot.portfolio.count) 份作品"
        } else {
            focusID = evidence.first?.capabilityID
            headline = "先完成第一份作品，报告才会有你的学习证据"
        }

        return ChinLearningReport(
            practiceCount: snapshot.practiceCount,
            correctCount: snapshot.correctCount,
            portfolioCount: snapshot.portfolio.count,
            unresolvedMistakeCount: snapshot.unresolvedMistakes.count,
            activeDayCount: Set(snapshot.activityDates).count,
            streak: snapshot.currentStreak(now: now, calendar: calendar),
            capabilities: evidence,
            focusCapabilityID: focusID,
            headline: headline
        )
    }
}

public struct ChinPlanDay: Identifiable, Codable, Hashable {
    public let id: String
    public let date: Date
    public let taskID: String
    public let title: String
    public let subtitle: String
    public let capabilityID: String
    public let estimatedMinutes: Int
    public let isCompleted: Bool
}

public struct ChinWeeklyPlan: Codable, Hashable {
    public let startDate: Date
    public let days: [ChinPlanDay]

    public var completedCount: Int {
        days.filter(\.isCompleted).count
    }

    public var progress: Double {
        guard !days.isEmpty else { return 0 }
        return Double(completedCount) / Double(days.count)
    }

    public static func make(
        for date: Date = .now,
        snapshot: ChinLearningSnapshot,
        calendar: Calendar = .current
    ) -> ChinWeeklyPlan {
        let dayStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: dayStart)
        let daysFromMonday = (weekday + 5) % 7
        let startDate = calendar.date(byAdding: .day, value: -daysFromMonday, to: dayStart) ?? dayStart
        let grade = ChinGradeLevel(rawValue: snapshot.gradeID) ?? .middle

        let days = (0..<7).compactMap { offset -> ChinPlanDay? in
            guard let planDate = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
            let task = ChinDailyTaskCatalog.task(for: planDate, grade: grade, calendar: calendar)
            return ChinPlanDay(
                id: dayKey(for: planDate, calendar: calendar),
                date: planDate,
                taskID: task.id,
                title: task.title,
                subtitle: task.subtitle,
                capabilityID: task.capabilityID,
                estimatedMinutes: task.estimatedMinutes,
                isCompleted: snapshot.isTaskCompleted(task.id, on: planDate, calendar: calendar)
            )
        }

        return ChinWeeklyPlan(startDate: startDate, days: days)
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

public final class ChinLearningRepository {
    public private(set) var snapshot: ChinLearningSnapshot

    private let defaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        defaults: UserDefaults = .standard,
        storageKey: String = "chintop.learning.snapshot"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        if let data = defaults.data(forKey: storageKey),
           let saved = try? decoder.decode(ChinLearningSnapshot.self, from: data) {
            snapshot = saved
        } else {
            snapshot = ChinLearningSnapshot()
        }
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.flushNow() }
        #endif
    }

    public func setGrade(_ grade: ChinGradeLevel) {
        snapshot.setGrade(grade)
        persist()
    }

    public func completeTask(_ taskID: String, date: Date = .now, calendar: Calendar = .current) {
        snapshot.completeTask(taskID, date: date, calendar: calendar)
        persist()
    }

    public func recordPractice(
        questionID: String,
        moduleID: String,
        capabilityID: String? = nil,
        gradeID: String? = nil,
        knowledgePointID: String? = nil,
        difficulty: String? = nil,
        skill: String,
        prompt: String,
        selectedAnswer: String,
        correctAnswer: String,
        explanation: String,
        isCorrect: Bool,
        date: Date = .now,
        calendar: Calendar = .current
    ) {
        snapshot.recordPractice(
            questionID: questionID,
            moduleID: moduleID,
            capabilityID: capabilityID,
            gradeID: gradeID,
            knowledgePointID: knowledgePointID,
            difficulty: difficulty,
            skill: skill,
            prompt: prompt,
            selectedAnswer: selectedAnswer,
            correctAnswer: correctAnswer,
            explanation: explanation,
            isCorrect: isCorrect,
            date: date,
            calendar: calendar
        )
        persist()
    }

    public func savePortfolio(
        task: ChinDailyTask,
        response: String,
        reflection: String,
        checklist: [String: Bool],
        date: Date = .now,
        calendar: Calendar = .current
    ) {
        snapshot.savePortfolio(
            task: task,
            response: response,
            reflection: reflection,
            checklist: checklist,
            date: date,
            calendar: calendar
        )
        persist()
    }

    public func resolveMistake(_ id: String, date: Date = .now, calendar: Calendar = .current) {
        guard let index = snapshot.mistakes.firstIndex(where: { $0.id == id }) else { return }
        snapshot.mistakes[index].isResolved = true
        snapshot.mistakes[index].reviewCount += 1
        snapshot.mistakes[index].lastAttemptAt = date
        snapshot.completeTask("mistake-review-\(id)", date: date, calendar: calendar)
        persist()
    }

    /// 合并写入：一次作答里的多次改动只在 0.25 秒后落盘一次。
    private var needsSave = false
    private var saveScheduled = false

    private func persist() {
        needsSave = true
        guard !saveScheduled else { return }
        saveScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.saveScheduled = false
            if self.needsSave { self.flushNow() }
        }
    }

    /// 立即落盘（App 进入后台时必须调用，避免丢数据）。
    public func flushNow() {
        needsSave = false
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
