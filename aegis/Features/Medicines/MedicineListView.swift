//
//  MedicineListView.swift
//  aegis
//

import SwiftData
import SwiftUI

enum MedicineSort: String, CaseIterable, Identifiable {
    case expiry
    case name
    case person

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .expiry: L10n.Medicines.sortByExpiry
        case .name: L10n.Medicines.sortByName
        case .person: L10n.Medicines.sortByPerson
        }
    }
}

/// Full cabinet list with search and sections grouped by expiry status.
struct MedicineListView: View {
    @Environment(AppState.self) private var appState
    @Environment(MedicineRepository.self) private var repository
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.scenePhase) private var scenePhase

    @Query(filter: MedicineQueries.active, sort: MedicineQueries.byExpiry)
    private var medicines: [Medicine]

    @State private var searchText = ""
    @State private var tokens: [MedicineSearchToken] = []
    @State private var sort: MedicineSort = .expiry
    @State private var medicinePendingDeletion: Medicine?
    @FocusState private var isSearchFocused: Bool
    @State private var now = Date.now

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            content
                .navigationTitle(Text(L10n.Medicines.title))
                .toolbar { toolbarContent }
                .navigationDestination(for: Medicine.self) { medicine in
                    MedicineDetailView(medicine: medicine)
                }
                .searchable(
                    text: $searchText,
                    tokens: $tokens,
                    suggestedTokens: .constant(suggestedTokens),
                    prompt: Text(L10n.Medicines.searchPrompt)
                ) { token in
                    Label(token.label, systemImage: token.symbolName)
                }
                .searchFocused($isSearchFocused)
                .onChange(of: appState.isSearchFocusRequested, initial: true) {
                    guard appState.isSearchFocusRequested else { return }
                    isSearchFocused = true
                    appState.isSearchFocusRequested = false
                }
                .confirmationDialog(
                    Text(L10n.Medicines.deleteConfirmTitle),
                    isPresented: deletionDialogBinding,
                    titleVisibility: .visible,
                    presenting: medicinePendingDeletion
                ) { medicine in
                    Button(L10n.Common.delete, role: .destructive) {
                        MedicineActions.delete(medicine, in: repository)
                        medicinePendingDeletion = nil
                    }
                    Button(L10n.Common.cancel, role: .cancel) {
                        medicinePendingDeletion = nil
                    }
                } message: { _ in
                    Text(L10n.Medicines.deleteConfirmMessage)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { now = .now }
                }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if medicines.isEmpty {
            EmptyStateView(
                systemImage: "cross.case",
                title: L10n.Medicines.emptyTitle,
                message: L10n.Medicines.emptyMessage,
                actionTitle: L10n.Medicines.add) {
                    appState.isPresentingNewMedicine = true
                }
                .background(Theme.Palette.canvas)
        } else if visibleMedicines.isEmpty {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: L10n.Medicines.noResultsTitle,
                message: L10n.Medicines.noResultsMessage)
                .background(Theme.Palette.canvas)
        } else {
            list
        }
    }

    private var list: some View {
        List {
            if appState.medicinesFilter != .all {
                Section {
                    Button {
                        appState.medicinesFilter = .all
                    } label: {
                        Label {
                            Text(appState.medicinesFilter.label)
                        } icon: {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Palette.brandDeep)
                    }
                }
            }

            ForEach(sections, id: \.status) { section in
                Section {
                    ForEach(section.medicines, id: \.uuid) { medicine in
                        NavigationLink(value: medicine) {
                            MedicineRow(medicine: medicine, now: now)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if subscriptionStore.isPro {
                                Button(role: .destructive) {
                                    let result = MedicineActions.archive(
                                        medicine,
                                        reason: medicine.defaultArchiveReason(now: now),
                                        in: repository)
                                    if case .failure(.requiresPro) = result {
                                        appState.presentPaywall()
                                    }
                                } label: {
                                    Label(L10n.Detail.archive, systemImage: "archivebox.fill")
                                }
                                .accessibilityHint(Text(L10n.Expired.footnote))
                            } else {
                                Button(role: .destructive) {
                                    medicinePendingDeletion = medicine
                                } label: {
                                    Label(L10n.Common.delete, systemImage: "trash.fill")
                                }
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                MedicineActions.setOpened(
                                    !medicine.isOpened, for: medicine, in: repository)
                            } label: {
                                Label(
                                    medicine.isOpened
                                        ? L10n.Detail.markUnopened
                                        : L10n.Detail.markOpened,
                                    systemImage: medicine.isOpened
                                        ? "seal"
                                        : "checkmark.seal.fill")
                            }
                            .tint(Theme.Palette.opened)
                        }
                    }
                } header: {
                    Text(section.status.sectionTitle)
                        .foregroundStyle(section.status.tint)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.Palette.canvas)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button {
                appState.isPresentingSettings = true
            } label: {
                Label(L10n.Settings.title, systemImage: "gearshape")
            }
        }

        ToolbarItem {
            Menu {
                Picker(selection: $sort) {
                    ForEach(MedicineSort.allCases) { option in
                        Text(option.label).tag(option)
                    }
                } label: {
                    Text(L10n.Medicines.sort)
                }
                .pickerStyle(.inline)
            } label: {
                Label(L10n.Medicines.sort, systemImage: "arrow.up.arrow.down")
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                appState.isPresentingNewMedicine = true
            } label: {
                Label(L10n.Medicines.add, systemImage: "plus")
            }
        }
    }

    // MARK: - Filtering

    private var suggestedTokens: [MedicineSearchToken] {
        medicines.searchTokenSuggestions(matching: searchText)
    }

    private var visibleMedicines: [Medicine] {
        var result = medicines.filter { appState.medicinesFilter.matches($0, now: now) }

        for token in tokens {
            result = result.filter { token.matches($0) }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            result = result.filter { $0.matches(freeText: query) }
        }

        return sorted(result)
    }

    private func sorted(_ medicines: [Medicine]) -> [Medicine] {
        switch sort {
        case .expiry:
            medicines.sorted { $0.effectiveExpiryDate < $1.effectiveExpiryDate }
        case .name:
            medicines.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .person:
            medicines.sorted {
                let comparison = $0.personName.localizedStandardCompare($1.personName)
                return comparison == .orderedSame
                    ? $0.effectiveExpiryDate < $1.effectiveExpiryDate
                    : comparison == .orderedAscending
            }
        }
    }

    private struct StatusSection {
        let status: MedicineStatus
        let medicines: [Medicine]
    }

    private var sections: [StatusSection] {
        let grouped = Dictionary(grouping: visibleMedicines) { $0.status(now: now) }
        return [MedicineStatus.expired, .expiringSoon, .valid].compactMap { status in
            guard let items = grouped[status], !items.isEmpty else { return nil }
            return StatusSection(status: status, medicines: items)
        }
    }

    private var deletionDialogBinding: Binding<Bool> {
        Binding(
            get: { medicinePendingDeletion != nil },
            set: { if !$0 { medicinePendingDeletion = nil } })
    }
}

#Preview {
    let container = PreviewData.container
    let services = AppServices(modelContainer: container)
    return MedicineListView()
        .environment(AppState())
        .environment(services.subscriptionStore)
        .environment(services.repository)
        .modelContainer(container)
}
