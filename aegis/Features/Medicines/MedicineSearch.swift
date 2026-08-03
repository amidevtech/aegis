//
//  MedicineSearch.swift
//  aegis
//

import Foundation

nonisolated extension String {
    /// Normalized form for search comparisons: case- and diacritic-insensitive.
    ///
    /// System diacritic folding does not map "ł" to "l", because it is a separate
    /// letter rather than an "l" with a diacritic. Without a manual replacement,
    /// searching for "gardla" would not match "ból gardła".
    var searchNormalized: String {
        folding(
            options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
            locale: .current
        )
        .replacingOccurrences(of: "ł", with: "l")
    }

    func searchContains(_ other: String) -> Bool {
        let needle = other.searchNormalized
        guard !needle.isEmpty else { return false }
        return searchNormalized.contains(needle)
    }
}

/// Token that narrows search to a single field.
///
/// Free text searches every field at once; a token lets the user specify
/// a person, indication, or active substance.
nonisolated struct MedicineSearchToken: Identifiable, Hashable {
    enum Field: String, Hashable {
        case person
        case indication
        case substance
    }

    let field: Field
    let value: String

    var id: String { "\(field.rawValue)-\(value.lowercased())" }

    var symbolName: String {
        switch field {
        case .person: "person.text.rectangle.fill"
        case .indication: "stethoscope"
        case .substance: "pill.fill"
        }
    }

    var label: LocalizedStringResource {
        switch field {
        case .person: L10n.Search.personToken(value)
        case .indication: L10n.Search.indicationToken(value)
        case .substance: L10n.Search.substanceToken(value)
        }
    }

    func matches(_ medicine: Medicine) -> Bool {
        switch field {
        case .person: medicine.personName.searchContains(value)
        case .indication: medicine.indication.searchContains(value)
        case .substance: medicine.activeSubstance.searchContains(value)
        }
    }
}

extension Medicine {
    /// Free-text search covers every descriptive field at once.
    func matches(freeText query: String) -> Bool {
        let fields = [name, activeSubstance, personName, indication, quantity, notes]
        return fields.contains { $0.searchContains(query) }
    }

    func defaultArchiveReason(now: Date = .now) -> ArchiveReason {
        status(now: now) == .expired ? .expired : .removed
    }
}

extension Collection where Element == Medicine {
    /// Token suggestions built from values the user has already entered.
    func searchTokenSuggestions(matching query: String, limit: Int = 6) -> [MedicineSearchToken] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        var seen = Set<String>()
        var suggestions: [MedicineSearchToken] = []

        func consider(_ value: String, field: MedicineSearchToken.Field) {
            let cleaned = value.trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty, cleaned.searchContains(trimmed) else { return }
            let token = MedicineSearchToken(field: field, value: cleaned)
            guard seen.insert(token.id).inserted else { return }
            suggestions.append(token)
        }

        for medicine in self {
            consider(medicine.personName, field: .person)
            consider(medicine.indication, field: .indication)
            consider(medicine.activeSubstance, field: .substance)
        }

        return Array(suggestions.prefix(limit))
    }

    /// Unique, sorted field values — used as form suggestions.
    func uniqueValues(for keyPath: KeyPath<Medicine, String>) -> [String] {
        var seen = Set<String>()
        var values: [String] = []
        for medicine in self {
            let value = medicine[keyPath: keyPath].trimmingCharacters(in: .whitespaces)
            guard !value.isEmpty, seen.insert(value.lowercased()).inserted else { continue }
            values.append(value)
        }
        return values.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}
