//
//  L10n.swift
//  aWordaDay
//
//  Centralized UI string localization.
//  The app now ships with English-only explanations and UI copy.
//

import Foundation

enum L10n {
    private static let zh = false

    // MARK: - Tabs
    enum Tabs {
        static var learn: String { zh ? "学习" : "Learn" }
        static var browse: String { zh ? "浏览" : "Browse" }
        static var games: String { zh ? "游戏" : "Games" }
        static var settings: String { zh ? "设置" : "Settings" }
    }

    // MARK: - Common
    enum Common {
        static var done: String { zh ? "完成" : "Done" }
        static var cancel: String { zh ? "取消" : "Cancel" }
        static var save: String { zh ? "保存" : "Save" }
        static var close: String { zh ? "关闭" : "Close" }
        static var skip: String { zh ? "跳过" : "Skip" }
        static var continueButton: String { zh ? "继续" : "Continue" }
        static var next: String { zh ? "下一个" : "Next" }
        static var retry: String { zh ? "重试" : "Retry" }
        static var ok: String { zh ? "好" : "OK" }
        static var enable: String { zh ? "启用" : "Enable" }
        static var enabled: String { zh ? "已启用" : "Enabled" }
        static var disabled: String { zh ? "已禁用" : "Disabled" }
        static var options: String { zh ? "选项" : "Options" }
        static var examples: String { zh ? "例句" : "Examples" }
        static var more: String { zh ? "更多" : "More" }
        static var less: String { zh ? "收起" : "Less" }
    }

    // MARK: - Difficulty
    enum Difficulty {
        static var beginner: String { zh ? "初级" : "Beginner" }
        static var intermediate: String { zh ? "中级" : "Intermediate" }
        static var advanced: String { zh ? "高级" : "Advanced" }
        static var easy: String { zh ? "简单" : "Easy" }
        static var medium: String { zh ? "中等" : "Medium" }
        static var hard: String { zh ? "困难" : "Hard" }
        static var easySummary: String { zh ? "A1-A2 词汇" : "A1-A2 words" }
        static var mediumSummary: String { zh ? "B1 词汇" : "B1 words" }
        static var hardSummary: String { zh ? "B2-C2 词汇" : "B2-C2 words" }
        static var mixAllLevels: String { zh ? "混合所有级别" : "Mix all levels" }
        static var mixAllLevelsDesc: String { zh ? "混合简单、中等和困难词汇以增加多样性" : "Mix easy, medium, and hard words for variety" }
        static var chooseYourLevel: String { zh ? "选择你的级别" : "Choose Your Level" }
        static var selectDifficultyDesc: String { zh ? "选择最适合你当前节奏的词汇难度" : "Choose the word difficulty that best matches your current pace" }
        static var commonEverydayWords: String { zh ? "适合日常生活和简单对话的基础词汇" : "Core vocabulary for daily life and simple conversations" }
        static var moderateVocab: String { zh ? "以 B1 为主，适合更自然的对话和阅读" : "Mostly B1 vocabulary for more natural conversations and reading" }
        static var complexTerms: String { zh ? "以 B2-C2 为主，适合更细腻和进阶的德语表达" : "Mostly B2-C2 vocabulary for more nuanced and advanced German" }
        static var examplesLabel: String { zh ? "示例：" : "Examples:" }
    }

    // MARK: - Home
    enum Home {
        static var noWordsYet: String { zh ? "还没有单词" : "No words yet" }
        static var noWordsDesc: String { zh ? "在设置中添加词汇或导入词库以开始学习。" : "Add some vocabulary or import a pack from Settings to start learning." }
        static var openSettings: String { zh ? "打开设置" : "Open Settings" }
        static var askWortyAbout: String { zh ? "问Worty关于这个词" : "Ask Worty about this word" }
        static var listenToPronunciation: String { zh ? "听发音" : "Listen to pronunciation" }
    }

    // MARK: - Word Detail
    enum WordDetail {
        static var conjugation: String { zh ? "动词变位" : "Conjugation" }
        static var usageNotes: String { zh ? "用法说明" : "Usage Notes" }
        static var relatedWords: String { zh ? "相关词汇" : "Related Words" }
        static var didYouKnow: String { zh ? "你知道吗？" : "Did you know?" }
        static var details: String { zh ? "详情" : "Details" }
        static var noAdditionalDetails: String { zh ? "这个词目前还没有更多内容。" : "No additional details are available for this word yet." }
        static var wordDetails: String { zh ? "词汇详情" : "Word Details" }
        static var pluralForm: String { zh ? "复数形式" : "Plural Form" }
        static var cefrLevel: String { zh ? "难度" : "Difficulty" }
        static func plural(_ p: String) -> String { zh ? "复数：\(p)" : "Plural: \(p)" }
        static func studying(_ word: String) -> String { zh ? "正在学习：\(word)" : "Studying: \(word)" }
        static var shareWord: String { zh ? "分享单词" : "Share Word" }
        static var playPronunciation: String { zh ? "播放发音" : "Play pronunciation" }
        static var playSlowly: String { zh ? "慢速播放" : "Play pronunciation slowly" }
        static var addToFavorites: String { zh ? "加入收藏" : "Add to favorites" }
        static var removeFromFavorites: String { zh ? "移除收藏" : "Remove from favorites" }
        static var moreOptions: String { zh ? "更多选项" : "More options" }
        static var questWord: String { zh ? "任务词汇" : "Quest word" }
        static var hintUsed: String { zh ? "已使用提示" : "Hint used" }
        static var tapToRevealMeaning: String { zh ? "点击查看释义" : "Tap to reveal meaning" }
        static var revealingSpoil: String { zh ? "揭示释义将影响下一个问题。" : "Revealing will spoil the next question." }
        static var revealMeaning: String { zh ? "揭示释义？" : "Reveal meaning?" }
        static var revealMeaningAlert: String { zh ? "这将影响接下来的翻译问题。" : "This will spoil the upcoming translation question." }
        static var reveal: String { zh ? "揭示" : "Reveal" }
    }

    // MARK: - Recall Quiz
    enum RecallQuiz {
        static var quickRecall: String { zh ? "快速回忆" : "Quick Recall" }
        static var whatDoes: String { zh ? "这个词是什么意思" : "What does" }
        static var mean: String { zh ? "？" : "mean?" }
    }

    // MARK: - Browse
    enum Browse {
        static var browseWords: String { zh ? "浏览单词" : "Browse Words" }
        static var searchPlaceholder: String { zh ? "搜索单词…" : "Search words..." }
        static var favorites: String { zh ? "收藏" : "Favorites" }
        static var clear: String { zh ? "清除" : "Clear" }
        static var noWordsFound: String { zh ? "未找到单词" : "No words found" }
        static var adjustFilters: String { zh ? "试着调整筛选条件或搜索词" : "Try adjusting your filters or search terms" }
        static var suggestions: String { zh ? "建议" : "Suggestions" }
        static var clearFilters: String { zh ? "清除筛选" : "Clear filters" }
        static var resetSearch: String { zh ? "重置搜索" : "Reset search" }
        static var learned: String { zh ? "已学" : "Learned" }
        static var notLearned: String { zh ? "未学" : "Not learned" }
        static func wordsCount(_ n: Int) -> String { zh ? "\(n) 个单词" : "\(n) words" }
        static func activeCount(_ n: Int) -> String { zh ? "• \(n) 个筛选" : "• \(n) active" }
        // Progress filter
        static var all: String { zh ? "全部" : "All" }
        static var learning: String { zh ? "学习中" : "Learning" }
        static var due: String { zh ? "待复习" : "Due" }
        // Sort
        static var dateAdded: String { zh ? "添加日期" : "Date Added" }
        static var alphabetical: String { zh ? "字母排序" : "Alphabetical" }
        static var difficulty: String { zh ? "难度" : "Difficulty" }
    }

    // MARK: - Stats
    enum Stats {
        static var stats: String { zh ? "统计" : "Stats" }
        static var streak: String { zh ? "连续" : "Streak" }
        static var level: String { zh ? "等级" : "Level" }
        static var learningSection: String { zh ? "学习" : "Learning" }
        static var discovered: String { zh ? "已发现" : "Discovered" }
        static var mastered: String { zh ? "已掌握" : "Mastered" }
        static var xp: String { zh ? "经验值" : "XP" }
        static var recentlyDiscovered: String { zh ? "最近发现" : "Recently discovered" }
        static func levelN(_ n: Int) -> String { zh ? "等级 \(n)" : "Level \(n)" }
        static func xpTotal(_ n: Int) -> String { zh ? "\(n) 经验值" : "\(n) XP total" }
        static func xpToLevel(_ current: Int, _ needed: Int, _ next: Int) -> String {
            zh ? "\(current) / \(needed) 经验值升至等级 \(next)" : "\(current) / \(needed) XP to level \(next)"
        }
        static func discoveredOf(_ n: Int, _ total: Int) -> String {
            zh ? "已发现 \(n) / \(total) 个单词" : "\(n) of \(total) words discovered"
        }
        static var dayStreak: String { zh ? "天连续" : "day streak" }
        static func longestStreak(_ n: Int) -> String { zh ? "最长：\(n) 天" : "Longest: \(n) days" }
    }

    // MARK: - Chat
    enum Chat {
        static var chatWithWorty: String { zh ? "与Worty聊天" : "Chat with Worty" }
        static var emptyTitle: String { zh ? "你好！我是Worty" : "Hallo! I'm Worty" }
        static var emptySubtitle: String { zh ? "问我任何关于德语单词、语法或发音的问题！" : "Ask me anything about German words, grammar, or pronunciation!" }
        static var inputPlaceholder: String { zh ? "问Worty…" : "Ask Worty..." }
        // Generic suggestion chips (no word context)
        static var chipTeachNewWord: String { zh ? "教我一个新单词" : "Teach me a new word" }
        static var chipExplainCases: String { zh ? "解释德语格" : "Explain German cases" }
        static var chipCommonPhrases: String { zh ? "常用短语" : "Common phrases" }
        // Word-context suggestion chips
        static var chipMoreExamples: String { zh ? "更多例句" : "More examples" }
        static var chipUseInSentence: String { zh ? "用这个词造句" : "Use in a sentence" }
        static var chipConjugatePast: String { zh ? "过去时变位" : "Conjugate in past tense" }
        static var chipHabenOderSein: String { zh ? "haben还是sein？" : "haben or sein?" }
        static var chipSimilarVerbs: String { zh ? "类似动词" : "Similar verbs" }
        static var chipComparativeSuperlative: String { zh ? "比较级和最高级" : "Comparative & superlative" }
        static var chipOpposite: String { zh ? "反义词是什么？" : "What's the opposite?" }
        static var chipSimilarAdjectives: String { zh ? "类似形容词" : "Similar adjectives" }
        static var chipExplainGrammar: String { zh ? "解释语法" : "Explain the grammar" }
        static var chipSimilarWords: String { zh ? "类似词汇" : "Similar words" }
    }

    // MARK: - Games
    enum Games {
        static var gamesTitle: String { zh ? "游戏" : "Games" }
        static var gamesSubtitle: String { zh ? "通过有趣的小游戏练习德语" : "Practice German with fun mini-games" }
        static var offlineBanner: String { zh ? "部分游戏需要网络连接" : "Some games require an internet connection" }
        static func needWords(_ n: Int) -> String { zh ? "需要 \(n)+ 个单词" : "Need \(n)+ words" }

        // Game titles
        static var derDieDas: String { "Der, Die, Das" } // stays German
        static var vocabSprint: String { zh ? "词汇冲刺" : "Vocab Sprint" }
        static var wordDetective: String { zh ? "单词侦探" : "Word Detective" }
        static var wordQuest: String { zh ? "单词冒险" : "Word Quest" }

        // Game descriptions
        static var derDieDasDesc: String { zh ? "为德语名词选择正确的冠词" : "Pick the correct article for German nouns" }
        static var vocabSprintDesc: String { zh ? "60秒内翻译尽可能多的单词" : "Translate as many words as you can in 60 seconds" }
        static var wordDetectiveDesc: String { zh ? "AI生成线索——猜猜神秘单词" : "AI generates clues — guess the mystery word" }
        static var wordQuestDesc: String { zh ? "D&D风格冒险——通过故事学德语" : "A D&D-style adventure — learn German through story" }

        // In-game
        static var whatArticle: String { zh ? "这个名词的冠词是什么？" : "What article does this noun take?" }
        static var correct: String { zh ? "正确！" : "Correct!" }
        static func itsArticle(_ a: String) -> String { zh ? "是 \"\(a)\"" : "It's \"\(a)\"" }
        static var getReady: String { zh ? "准备好了！" : "Get Ready!" }
        static var generatingClue: String { zh ? "正在生成线索…" : "Generating clue..." }
        static var skipRound: String { zh ? "跳过本轮" : "Skip Round" }
        static var couldntGenerateClue: String { zh ? "无法生成线索。试试跳过。" : "Couldn't generate clue. Try skipping." }
        static var couldntLoadStory: String { zh ? "无法加载故事。点击跳过。" : "Couldn't load the story. Tap to skip." }
        static var retryBeat: String { zh ? "重试" : "Retry Beat" }
        static var skipBeat: String { zh ? "跳过" : "Skip Beat" }
        static var chooseAdventure: String { zh ? "选择你的冒险" : "Choose your adventure" }
        static var whatDoYouDo: String { zh ? "你会怎么做？" : "What do you do?" }

        // Game Result
        static var perfect: String { zh ? "完美！" : "Perfect!" }
        static var greatJob: String { zh ? "太棒了！" : "Great Job!" }
        static var goodEffort: String { zh ? "不错的尝试！" : "Good Effort!" }
        static var keepPracticing: String { zh ? "继续练习！" : "Keep Practicing!" }
        static var playAgain: String { zh ? "再玩一次" : "Play Again" }
        static func ofTotal(_ n: Int) -> String { zh ? "共 \(n) 题" : "of \(n)" }
        static func sprintResult(_ n: Int) -> String { zh ? "你在60秒内答对了 \(n) 题" : "You got \(n) correct in 60 seconds" }
        static func standardResult(_ correct: Int, _ total: Int) -> String {
            zh ? "你答对了 \(correct) / \(total) 题" : "You got \(correct) out of \(total) correct"
        }
        static func levelUp(_ n: Int) -> String { zh ? "升级了！你现在是等级 \(n)" : "Level Up! You're now level \(n)" }
    }

    // MARK: - Settings
    enum Settings {
        static var settings: String { zh ? "设置" : "Settings" }
        static var smartNotifications: String { zh ? "智能通知" : "Smart Notifications" }
        static var notificationSettings: String { zh ? "通知设置" : "Notification Settings" }
        static var configureReminders: String { zh ? "配置智能提醒和通知" : "Configure smart reminders & alerts" }
        static var progress: String { zh ? "进度" : "Progress" }
        static var wordsAvailable: String { zh ? "可用单词" : "Words Available" }
        static var favorites: String { zh ? "收藏" : "Favorites" }
        static var learningSection: String { zh ? "学习" : "Learning" }
        static var difficultyLevel: String { zh ? "难度级别" : "Difficulty Level" }
        static var displayLanguage: String { zh ? "显示语言" : "Display Language" }
        static var about: String { zh ? "关于" : "About" }
        static var appVersion: String { zh ? "应用版本" : "App Version" }
        static var contactDeveloper: String { zh ? "联系开发者" : "Contact Developer" }
        static var mixedAllLevels: String { zh ? "混合 - 简单、中等、困难" : "Mixed - Easy, Medium & Hard" }
        static var notSet: String { zh ? "未设置" : "Not set" }
        static var difficultyPickerDesc: String { zh ? "选择你想看到的词汇难度。这有助于我们为你推荐更合适的单词。" : "Choose the word difficulty you want to see. This helps us suggest words that fit you better." }
        static var languagePickerDesc: String { zh ? "选择翻译和解释的语言。德语单词和发音保持不变。" : "Choose the language for translations and explanations. German words and pronunciation stay the same." }
    }

    // MARK: - Onboarding
    enum Onboarding {
        static var welcomeToWorty: String { zh ? "欢迎来到Worty！" : "Welcome to Worty!" }
        static var pickLevel: String { zh ? "选择你的级别开始" : "Pick your level to get started" }
        static var explanationsIn: String { zh ? "解释语言：" : "Explanations in:" }
        static var whatYoullGet: String { zh ? "你将获得" : "What You'll Get" }
        static var everythingToMaster: String { zh ? "掌握德语所需的一切" : "Everything you need to master German" }
        static var dailyWords: String { zh ? "每日单词" : "Daily Words" }
        static var dailyWordsDesc: String { zh ? "每天学习精选单词，结合间隔重复" : "Learn curated words every day with spaced repetition" }
        static var smartReview: String { zh ? "智能复习" : "Smart Review" }
        static var smartReviewDesc: String { zh ? "根据你的学习节奏循环安排新词和复习词" : "Rotate new and due words based on your learning pace" }
        static var browseLibrary: String { zh ? "浏览词库" : "Browse Library" }
        static var browseLibraryDesc: String { zh ? "快速搜索、筛选和重看你已经学过的词" : "Search, filter, and revisit the words you've already seen" }
        static var funGames: String { zh ? "趣味游戏" : "Fun Games" }
        static var funGamesDesc: String { zh ? "通过冠词游戏、单词冒险等练习" : "Practice with Der/Die/Das, Word Quest, and more" }
        static var aiTutor: String { zh ? "AI导师" : "AI Tutor" }
        static var aiTutorDesc: String { zh ? "与Worty聊天，询问任何单词的问题" : "Chat with Worty to ask questions about any word" }
        static var youreAllSet: String { zh ? "一切就绪！" : "You're All Set!" }
        static var letsStart: String { zh ? "开始你的学习之旅" : "Let's start your learning journey" }
        static var getStarted: String { zh ? "开始" : "Get Started" }
    }

    // MARK: - Progress
    enum Progress {
        static var yourProgress: String { zh ? "你的进度" : "Your Progress" }
        static var weeklyGoal: String { zh ? "每周目标" : "Weekly Goal" }
        static func weeklyGoalOf(_ current: Int, _ goal: Int) -> String {
            zh ? "\(current) / \(goal) 天" : "\(current) of \(goal) days"
        }
        static var goalAchieved: String { zh ? "本周目标已达成！" : "Goal achieved this week!" }
        // ProgressStat enum titles
        static var streakTitle: String { zh ? "连续" : "Streak" }
        static var wordsLearnedTitle: String { zh ? "已学单词" : "Words Learned" }
        static var levelTitle: String { zh ? "等级" : "Level" }
    }

    // MARK: - Progress Stat Detail
    enum StatDetail {
        static var keepStreakOnFire: String { zh ? "保持你的连续记录！" : "Keep your streak on fire!" }
        static var learningAchievements: String { zh ? "你的学习成就" : "Your learning achievements" }
        static var levelProgressOverview: String { zh ? "等级进度概览" : "Level progress overview" }
        static func streakSubtitle(_ current: Int, _ longest: Int) -> String {
            current > 0
                ? (zh ? "你正在燃烧！最长连续：\(longest) 天。" : "You're on fire! Longest streak: \(longest) days.")
                : (zh ? "从今天开始建立你的第一个连续记录。" : "Start today to build your first streak.")
        }
        static func learnedSubtitleEmpty() -> String {
            zh ? "当你在应用中发现单词时，它们会出现在这里。" : "Words appear here as soon as you discover them in the app."
        }
        static func learnedSubtitleNoMastered() -> String {
            zh ? "继续复习单词以标记为完全掌握。" : "Keep revisiting words to mark them as fully mastered."
        }
        static func learnedSubtitleMastered(_ n: Int) -> String {
            zh ? "通过间隔复习完全掌握了 \(n) 个单词。" : "\(n) words fully mastered through spaced review."
        }
        static func levelSubtitle(_ remaining: Int, _ next: Int) -> String {
            remaining == 0
                ? (zh ? "你已经可以升级了！继续学习以进步。" : "You're eligible to level up! Keep learning to advance.")
                : (zh ? "还需 \(remaining) 经验值升至等级 \(next)。" : "\(remaining) XP to reach level \(next).")
        }
        static var learningMilestones: String { zh ? "学习里程碑" : "Learning milestones" }
        static var wordsDiscovered: String { zh ? "已发现单词" : "Words discovered" }
        static var fullyLearned: String { zh ? "完全学会" : "Fully learned" }
        static var xpCollected: String { zh ? "已收集经验值" : "XP collected" }
        static var discoverNewWords: String { zh ? "发现新单词以开始建立你的收藏。" : "Discover new words to start building your collection." }
        static var collectionDiscovered: String { zh ? "已发现收藏" : "Collection discovered" }
        static func discoveredOfWords(_ n: Int, _ total: Int) -> String {
            zh ? "已发现 \(n) / \(total) 个单词" : "\(n) of \(total) words discovered"
        }
        static func discoveredWordsSummary(_ n: Int) -> String {
            zh ? "已发现 \(n) 个单词。" : "\(n) words discovered."
        }
        static var browseDiscoveredWords: String { zh ? "浏览已发现的单词" : "Browse discovered words" }
        static var experienceTracker: String { zh ? "经验值追踪" : "Experience tracker" }
        static var currentLevel: String { zh ? "当前等级" : "Current level" }
        static var xpEarned: String { zh ? "已获经验值" : "XP earned" }
        static var nextLevelTarget: String { zh ? "下一等级目标" : "Next level target" }
        static var xpProgress: String { zh ? "经验值进度" : "XP progress" }
        static func xpThisLevel(_ current: Int, _ needed: Int) -> String {
            zh ? "本等级 \(current) / \(needed) 经验值" : "\(current) / \(needed) XP this level"
        }
        static func practiceBoost(_ word: String) -> String {
            zh ? "再次练习 \"\(word)\" 可以获得更多经验值。" : "Practicing \"\(word)\" again boosts your XP gains."
        }
        static var practiceWordNow: String { zh ? "现在练习一个单词" : "Practice a word now" }
        static var reviewTodaysWords: String { zh ? "复习今天的单词" : "Review today's words" }
    }

    // MARK: - Notifications
    enum Notifications {
        static var notifications: String { zh ? "通知" : "Notifications" }
        static var stayOnTrack: String { zh ? "通过智能提醒保持学习进度" : "Stay on track with smart reminders" }
        static var notificationPermission: String { zh ? "通知权限" : "Notification Permission" }
        static var dailyWord: String { zh ? "每日单词" : "Daily Word" }
        static var dailyWordDesc: String { zh ? "在你选择的时间推送每日词汇" : "Daily vocabulary word at your chosen time" }
        static var preferredTime: String { zh ? "首选时间" : "Preferred Time" }
        static var dailyReminderAt: String { zh ? "每日提醒于" : "Daily reminder at" }
        static var sendTestNotification: String { zh ? "发送测试通知" : "Send Test Notification" }
        static var testSent: String { zh ? "测试已发送！" : "Test Sent!" }
        static var checkNotifications: String { zh ? "几秒后查看你的通知！" : "Check your notifications in a few seconds!" }
        static var chooseNotificationTime: String { zh ? "选择通知时间" : "Choose Notification Time" }
        static var hour: String { zh ? "小时" : "Hour" }
        static var minute: String { zh ? "分钟" : "Minute" }
        static var setTime: String { zh ? "设置时间" : "Set Time" }
        // Permission descriptions
        static var permEnabled: String { zh ? "通知已启用并准备就绪" : "Notifications are enabled and ready" }
        static var permQuiet: String { zh ? "静默通知已启用" : "Quiet notifications are enabled" }
        static var permTemporary: String { zh ? "临时通知权限已启用" : "Temporary notification permission is active" }
        static var permDenied: String { zh ? "通知已禁用。在设置中启用。" : "Notifications are disabled. Enable in Settings." }
        static var permNotDetermined: String { zh ? "点击启用智能学习提醒" : "Tap to enable smart learning reminders" }
        static var permUnknown: String { zh ? "未知权限状态" : "Unknown permission status" }
        // Notification content
        static var dailyWordAwaits: String { zh ? "今日单词等你来学！" : "Your Daily Word Awaits!" }
        static var openAppToDiscover: String { zh ? "打开应用发现今天的单词！" : "Open the app to discover today's word and start learning!" }
        static var todaysWord: String { zh ? "今日单词" : "Today's Word" }
        static var learnColon: String { zh ? "学习" : "Learn" }
        static var newChallenge: String { zh ? "新挑战" : "New Challenge" }
        static var discoverColon: String { zh ? "发现" : "Discover" }
        static var testNotificationTitle: String { zh ? "🧪 测试通知" : "🧪 Test Notification" }
        static var testNotificationBody: String { zh ? "智能通知运行正常！" : "Smart notifications are working perfectly!" }
    }

    // MARK: - System / Errors
    enum System {
        static var aiServiceError: String { zh ? "AI服务错误" : "AI Service Error" }
        static var somethingWentWrong: String { zh ? "出了点问题" : "Something went wrong" }
        static var error: String { zh ? "错误" : "Error" }
        static var settingsAlert: String { zh ? "设置" : "Settings" }
    }

    // MARK: - Word Display
    enum WordDisplay {
        static var masculine: String { zh ? "阳性" : "Masculine" }
        static var feminine: String { zh ? "阴性" : "Feminine" }
        static var neuter: String { zh ? "中性" : "Neuter" }
    }

    // MARK: - WordQuest ViewModel flavor texts
    enum Quest {
        static var storyUnfolds: String { zh ? "故事展开了…" : "The story unfolds..." }
        static var pathContinues: String { zh ? "你的旅途继续…" : "Your path continues..." }
        static var newChapter: String { zh ? "新的篇章开始…" : "A new chapter begins..." }
        static var adventureDeepens: String { zh ? "冒险加深了…" : "The adventure deepens..." }
        static var whatLiesAhead: String { zh ? "前方有什么…" : "What lies ahead..." }
        // Scenario subtitles
        static var theMarket: String { zh ? "市场" : "The Market" }
        static var theCastle: String { zh ? "城堡" : "The Castle" }
        static var theForest: String { zh ? "森林" : "The Forest" }
    }
}
