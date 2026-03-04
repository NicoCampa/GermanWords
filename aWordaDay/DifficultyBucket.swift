import Foundation

enum DifficultyBucket: Int, CaseIterable, Hashable {
    case easy = 1
    case medium = 2
    case hard = 3

    init?(selection: Int?) {
        guard let selection, let bucket = DifficultyBucket(rawValue: selection) else {
            return nil
        }
        self = bucket
    }

    static func from(cefrLevel: String?, fallbackDifficultyLevel: Int) -> DifficultyBucket {
        switch normalizedCEFR(cefrLevel) {
        case "A1", "A2":
            return .easy
        case "B1":
            return .medium
        case "B2", "C1", "C2":
            return .hard
        default:
            switch fallbackDifficultyLevel {
            case ...1:
                return .easy
            case 2:
                return .medium
            default:
                return .hard
            }
        }
    }

    static func normalizedCEFR(_ rawValue: String?) -> String? {
        guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty else {
            return nil
        }
        return rawValue.uppercased()
    }

    var title: String {
        switch self {
        case .easy:
            return L10n.Difficulty.easy
        case .medium:
            return L10n.Difficulty.medium
        case .hard:
            return L10n.Difficulty.hard
        }
    }

    var levelSummary: String {
        switch self {
        case .easy:
            return L10n.Difficulty.easySummary
        case .medium:
            return L10n.Difficulty.mediumSummary
        case .hard:
            return L10n.Difficulty.hardSummary
        }
    }

    var description: String {
        switch self {
        case .easy:
            return L10n.Difficulty.commonEverydayWords
        case .medium:
            return L10n.Difficulty.moderateVocab
        case .hard:
            return L10n.Difficulty.complexTerms
        }
    }

    var exampleWords: [String] {
        switch self {
        case .easy:
            return ["Hallo", "Danke", "Guten Morgen"]
        case .medium:
            return ["meinen", "bemerken", "vergleichen"]
        case .hard:
            return ["hingegen", "beanspruchen", "verweisen"]
        }
    }

    var sqlFilterClause: String {
        switch self {
        case .easy:
            return "(UPPER(COALESCE(cefr_level, '')) IN ('A1', 'A2') OR (COALESCE(cefr_level, '') = '' AND difficulty_level <= 1))"
        case .medium:
            return "(UPPER(COALESCE(cefr_level, '')) = 'B1' OR (COALESCE(cefr_level, '') = '' AND difficulty_level = 2))"
        case .hard:
            return "(UPPER(COALESCE(cefr_level, '')) IN ('B2', 'C1', 'C2') OR (COALESCE(cefr_level, '') = '' AND difficulty_level >= 3))"
        }
    }

    static var sqlSortRankExpression: String {
        """
        CASE
            WHEN UPPER(COALESCE(cefr_level, '')) IN ('A1', 'A2') THEN 1
            WHEN UPPER(COALESCE(cefr_level, '')) = 'B1' THEN 2
            WHEN UPPER(COALESCE(cefr_level, '')) IN ('B2', 'C1', 'C2') THEN 3
            WHEN difficulty_level <= 1 THEN 1
            WHEN difficulty_level = 2 THEN 2
            ELSE 3
        END
        """
    }
}
