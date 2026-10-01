import Foundation

// MARK: - The string entry point

/// A localized string, resolved now. The one way code turns user-visible English
/// into text: write the English as a literal and the compiler extracts it into the
/// String Catalog (`Main/Resources/Localizable.xcstrings`) with its interpolations
/// as placeholders — `L("\(n) years")` is the key `%lld years`.
///
///     L("Your chance: \(Fmt.percent(p))")        // key "Your chance: %@"
///     String(localized: "Fee", comment: "…")      // same thing, with a translator note
///
/// Where a headless tool (BalanceSim, `run-tests.sh`) compiles the model layer there
/// is no catalog, so the English default comes back unchanged.
///
/// * One whole sentence per call. Never glue fragments (`L("You earn") + " " + …`):
///   word order differs between languages.
/// * Interpolate numbers as `Int` (`%lld`) or pre-formatted `String`s (`%@`), through `Fmt`.
/// * Counts that change the wording take a plural variation in the catalog (see `Tools/i18n`).
func L(_ resource: LocalizedStringResource) -> String {
    String(localized: resource)
}

// MARK: - Language

/// Which language the game is in, and how it writes numbers.
///
/// The language is the one the app's bundle resolves strings in — the device's
/// first preferred language that the app ships — so the text, the numbers and the
/// advisor always agree.
enum L10n {
    /// The languages the game ships in. Adding one: a `knownRegions` entry in the
    /// project, a case here, and its column in every `Tools/i18n/translations/*.json`.
    enum Language: String, CaseIterable {
        case english = "en"
        case german = "de"
        case french = "fr"
        case italian = "it"
        case japanese = "ja"
        case ukrainian = "uk"

        /// For prompts and logs: "German".
        var englishName: String {
            switch self {
            case .english: return "English"
            case .german: return "German"
            case .french: return "French"
            case .italian: return "Italian"
            case .japanese: return "Japanese"
            case .ukrainian: return "Ukrainian"
            }
        }

        /// What the language calls itself: "Deutsch".
        var nativeName: String {
            switch self {
            case .english: return "English"
            case .german: return "Deutsch"
            case .french: return "Français"
            case .italian: return "Italiano"
            case .japanese: return "日本語"
            case .ukrainian: return "Українська"
            }
        }

        /// The catalog's plural categories this language uses, for tooling and tests.
        var pluralCategories: [String] {
            switch self {
            case .english, .german: return ["one", "other"]
            case .french, .italian: return ["one", "many", "other"]
            case .japanese: return ["other"]
            case .ukrainian: return ["one", "few", "many", "other"]
            }
        }
    }

    /// Pins the language — for tests, the headless tools and previews. `nil` follows the app's bundle.
    static var languageOverride: Language?

    /// The language the game is showing.
    static var language: Language {
        if let languageOverride { return languageOverride }
        for identifier in Bundle.main.preferredLocalizations {
            let code = Locale(identifier: identifier).language.languageCode?.identifier ?? identifier
            if let match = Language(rawValue: code) { return match }
        }
        return .english
    }

    /// Numbers, lists and plurals are written in this locale: the game's language,
    /// with the device's region (so a German-language phone in Austria groups digits
    /// the Austrian way). Falls back to the plain language.
    static var locale: Locale {
        guard let region = Locale.current.region?.identifier, !region.isEmpty else {
            return Locale(identifier: language.rawValue)
        }
        return Locale(identifier: "\(language.rawValue)_\(region)")
    }

    // MARK: Catalogue strings

    /// Display text for a catalogue entry that is known by an English *id* — a job
    /// title, a training, an award. The id never changes; the text is looked up in
    /// `Catalogue.xcstrings` under `key` (a namespaced name such as `job.title.<id>`)
    /// and falls back to `english` where there is no translation, as in the headless tools.
    static func catalogue(_ key: String, english: String) -> String {
        Bundle.main.localizedString(forKey: key, value: english, table: "Catalogue")
    }
}

// MARK: - Formatting

/// Numbers and lists, written for the game's language. Every number a player reads
/// goes through here so the separators, the percent sign and the list words follow it.
enum Fmt {
    /// 45000 → "45,000" / "45.000" / "45 000".
    static func number(_ n: Int) -> String {
        n.formatted(.number.locale(L10n.locale))
    }

    /// A share as a rounded whole percent: 0.734 → "73%" (French: "73 %").
    static func percent(_ share: Double) -> String {
        (Double(Int((share * 100).rounded())) / 100)
            .formatted(.percent.precision(.fractionLength(0)).locale(L10n.locale))
    }

    /// A change as a signed whole percent: +0.2 → "+20%", −0.05 → "−5%".
    static func signedPercent(_ share: Double) -> String {
        (Double(Int((share * 100).rounded())) / 100)
            .formatted(.percent.precision(.fractionLength(0)).sign(strategy: .always(includingZero: false)).locale(L10n.locale))
    }

    /// A decimal with a fixed number of digits: 3.456 → "3.5" / "3,5".
    static func decimal(_ value: Double, digits: Int = 1) -> String {
        value.formatted(.number.precision(.fractionLength(digits)).locale(L10n.locale))
    }

    enum Conjunction { case and, or }

    /// "a, b and c" — or "a, b or c". English keeps its long-standing no-serial-comma
    /// form; every other language uses its own list pattern.
    static func list(_ items: [String], _ conjunction: Conjunction = .and) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        default:
            if L10n.language == .english {
                let word = conjunction == .and ? "and" : "or"
                return items.dropLast().joined(separator: ", ") + " \(word) " + items[items.count - 1]
            }
            let type: ListFormatStyle<StringStyle, [String]>.ListType = conjunction == .and ? .and : .or
            return items.formatted(.list(type: type, width: .standard).locale(L10n.locale))
        }
    }

    /// The first letter in capitals, for a sentence that starts with a looked-up word.
    /// Don't use it to *lower*-case: German nouns keep their capitals mid-sentence.
    static func capitalizingFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return String(first).uppercased(with: L10n.locale) + text.dropFirst()
    }
}
