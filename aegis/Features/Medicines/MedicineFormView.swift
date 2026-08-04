//
//  MedicineFormView.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Form for adding and editing a medicine. Only the name is required —
/// everything else can be filled in later.
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

    // MARK: - Sections

    private var medicineSection: some View {
        Section(L10n.Form.sectionMedicine) {
            formTextField(L10n.Form.name, text: $draft.name, prompt: L10n.Form.namePrompt)

            formTextField(
                L10n.Detail.substance,
                text: $draft.activeSubstance,
                prompt: L10n.Form.substancePrompt)
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

            formTextField(
                L10n.Detail.quantity,
                text: $draft.quantity,
                prompt: L10n.Form.quantityPrompt)
        }
    }

    private var prescriptionSection: some View {
        Section(L10n.Form.sectionPrescription) {
            formTextField(
                L10n.Detail.person,
                text: $draft.personName,
                prompt: L10n.Form.personPrompt)
            suggestions(for: \.personName) { draft.personName = $0 }

            formTextField(
                L10n.Detail.indication,
                text: $draft.indication,
                prompt: L10n.Form.indicationPrompt)
            suggestions(for: \.indication) { draft.indication = $0 }

            formTextField(
                L10n.Detail.dosage,
                text: $draft.dosage,
                prompt: L10n.Form.dosagePrompt)
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
            formTextField(
                L10n.Detail.notes,
                text: $draft.notes,
                prompt: L10n.Form.notesPrompt,
                axis: .vertical,
                lineLimit: 3...6)
        }
    }

    // MARK: - Fields

    @ViewBuilder
    private func formTextField(
        _ title: LocalizedStringResource,
        text: Binding<String>,
        prompt: LocalizedStringResource,
        axis: Axis = .horizontal,
        lineLimit: ClosedRange<Int>? = nil
    ) -> some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            labeledField(
                text: text,
                prompt: prompt,
                axis: axis,
                lineLimit: lineLimit)
            .accessibilityLabel(Text(title))
        }
        #else
        if let lineLimit {
            TextField(title, text: text, prompt: Text(prompt), axis: axis)
                .lineLimit(lineLimit)
        } else {
            TextField(title, text: text, prompt: Text(prompt), axis: axis)
        }
        #endif
    }

    #if os(iOS)
    @ViewBuilder
    private func labeledField(
        text: Binding<String>,
        prompt: LocalizedStringResource,
        axis: Axis,
        lineLimit: ClosedRange<Int>?
    ) -> some View {
        if let lineLimit {
            TextField("", text: text, prompt: Text(prompt), axis: axis)
                .lineLimit(lineLimit)
        } else {
            TextField("", text: text, prompt: Text(prompt), axis: axis)
        }
    }
    #endif

    // MARK: - Suggestions

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

    // MARK: - Save

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

#Preview("New medicine") {
    let container = PreviewData.container
    let services = AppServices(modelContainer: container)
    return MedicineFormView(mode: .create)
        .environment(services.repository)
        .modelContainer(container)
}

#Preview("Edit") {
    let container = PreviewData.container
    let services = AppServices(modelContainer: container)
    return MedicineFormView(mode: .edit(PreviewData.samples[2]))
        .environment(services.repository)
        .modelContainer(container)
}
