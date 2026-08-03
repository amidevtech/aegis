//
//  OpenMedicineControl.swift
//  aegis
//

import SwiftUI

/// Form section for marking a package opened and the post-opening expiry.
struct OpenMedicineControl: View {
    @Binding var draft: MedicineDraft

    var body: some View {
        Toggle(isOn: $draft.isOpened.animation(.snappy)) {
            Label(L10n.Form.opened, systemImage: "checkmark.seal.fill")
        }
        .tint(Theme.Palette.opened)

        if draft.isOpened {
            DatePicker(
                selection: $draft.openedAt,
                in: ...Date.now,
                displayedComponents: .date
            ) {
                Text(L10n.Form.openedAt)
            }

            Toggle(isOn: $draft.usesCustomOpenedDate.animation(.snappy)) {
                Text(L10n.Form.useCustomDate)
            }

            if draft.usesCustomOpenedDate {
                DatePicker(
                    selection: $draft.customOpenedExpiry,
                    displayedComponents: .date
                ) {
                    Text(L10n.Form.customDate)
                }
            } else {
                Stepper(value: $draft.daysAfterOpening, in: 1...730) {
                    LabeledContent {
                        Text(L10n.Form.days(draft.daysAfterOpening))
                            .foregroundStyle(Theme.Palette.brandDeep)
                            .contentTransition(.numericText())
                    } label: {
                        Text(L10n.Form.daysAfterOpening)
                    }
                }
            }
        }
    }
}
