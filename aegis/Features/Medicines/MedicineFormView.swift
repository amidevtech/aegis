//
//  MedicineFormView.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Formularz dodawania i edycji leku. Obowiązkowa jest tylko nazwa - resztę
/// można uzupełnić później.
struct MedicineFormView: View {
    enum Mode {
        case create
        case edit(Medicine)
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(MedicineRepository.self) private var repository

    @Query(sort: MedicineQueries.byName) private var allMedicines: [Medicine]

    @State private var draft = MedicineDraft()
    @State private var hasLoadedDraft = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                medicineSection
                prescriptionSection
                expirySection
                notesSection
            }
            .formStyle(.grouped)
            .navigationTitle(Text(isEditing ? L10n.Form.titleEdit : L10n.Form.titleNew))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save, action: save)
                        .disabled(!draft.isValid)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .onAppear(perform: loadDraftIfNeeded)
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 560)
        #endif
    }

    // MARK: - Sekcje

    private var medicineSection: some View {
        Section(L10n.Form.sectionMedicine) {
            TextField(L10n.Form.name, text: $draft.name, prompt: Text(L10n.Form.namePrompt))

            TextField(
                L10n.Detail.substance,
                text: $draft.activeSubstance,
                prompt: Text(L10n.Form.substancePrompt))
            suggestions(for: \.activeSubstance) { draft.activeSubstance = $0 }

            Picker(selection: $draft.form) {
                ForEach(MedicineForm.allCases) { form in
                    Label(form.label, systemImage: form.symbolName).tag(form)
                }
            } label: {
                Text(L10n.Detail.form)
            }
            .onChange(of: draft.form) { _, newValue in
                draft.applySuggestedShelfLife(for: newValue)
            }

            TextField(
                L10n.Detail.quantity,
                text: $draft.quantity,
                prompt: Text(L10n.Form.quantityPrompt))
        }
    }

    private var prescriptionSection: some View {
        Section(L10n.Form.sectionPrescription) {
            TextField(
                L10n.Detail.person,
                text: $draft.personName,
                prompt: Text(L10n.Form.personPrompt))
            suggestions(for: \.personName) { draft.personName = $0 }

            TextField(
                L10n.Detail.indication,
                text: $draft.indication,
                prompt: Text(L10n.Form.indicationPrompt))
            suggestions(for: \.indication) { draft.indication = $0 }

            TextField(
                L10n.Detail.dosage,
                text: $draft.dosage,
                prompt: Text(L10n.Form.dosagePrompt))
        }
    }

    private var expirySection: some View {
        Section {
            DatePicker(
                selection: $draft.expiryDate,
                displayedComponents: .date
            ) {
                Text(L10n.Detail.expiry)
            }

            OpenMedicineControl(draft: $draft)
        } header: {
            Text(L10n.Form.sectionExpiry)
        } footer: {
            LabeledContent {
                Text(draft.effectiveExpiryDate.formatted(date: .abbreviated, time: .omitted))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Palette.brandDeep)
            } label: {
                Text(L10n.Detail.effectiveExpiry)
            }
            .font(.footnote)
            .padding(.top, 4)
        }
    }

    private var notesSection: some View {
        Section(L10n.Form.sectionNotes) {
            TextField(
                L10n.Detail.notes,
                text: $draft.notes,
                prompt: Text(L10n.Form.notesPrompt),
                axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Podpowiedzi

    @ViewBuilder
    private func suggestions(
        for keyPath: KeyPath<Medicine, String>,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        let values = allMedicines.uniqueValues(for: keyPath)
        if !values.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(values, id: \.self) { value in
                        Button(value) { onSelect(value) }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .accessibilityLabel(Text(L10n.Form.suggestions))
        }
    }

    // MARK: - Zapis

    private func loadDraftIfNeeded() {
        guard !hasLoadedDraft else { return }
        hasLoadedDraft = true
        if case .edit(let medicine) = mode {
            draft = MedicineDraft(from: medicine)
        }
    }

    private func save() {
        switch mode {
        case .create:
            let newMedicine = Medicine()
            draft.apply(to: newMedicine)
            repository.upsert(newMedicine, isNew: true)
        case .edit(let existing):
            draft.apply(to: existing)
            repository.upsert(existing, isNew: false)
        }

        dismiss()
    }
}

#Preview("Nowy lek") {
    let container = PreviewData.container
    let services = AppServices(modelContainer: container)
    return MedicineFormView(mode: .create)
        .environment(services.repository)
        .modelContainer(container)
}

#Preview("Edycja") {
    let container = PreviewData.container
    let services = AppServices(modelContainer: container)
    return MedicineFormView(mode: .edit(PreviewData.samples[2]))
        .environment(services.repository)
        .modelContainer(container)
}
