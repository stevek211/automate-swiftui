import SwiftUI

// Shared look for bottom-sheet forms, matching the Log Service sheet
// (LogMilestoneSheet): drag handle, caps eyebrow + title with a round close
// button, underlined fields with tracked caps labels, and a pinned Save bar.

enum FormSheetStyle {
    static var labelColor: Color { Color.theme.mutedText }
    static var underline: Color { Color.theme.borderStrong }
}

/// Header, scrolling form body and Save bar for a form sheet.
struct FormSheetScaffold<Content: View>: View {
    let eyebrow: String
    let title: String
    var saveTitle: String = "Save"
    let canSave: Bool
    let onClose: () -> Void
    let onSave: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            dragHandle
            header
            ScrollView {
                content()
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    // Tapping empty space closes the keyboard; fields and
                    // buttons handle their own taps first.
                    .contentShape(Rectangle())
                    .onTapGesture { dismissKeyboard() }
            }
            .scrollDismissesKeyboard(.interactively)
            saveArea
        }
        .keyboardDoneBar()
        .background(.white)
        .presentationDragIndicator(.hidden)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(FormSheetStyle.underline)
            .frame(width: 40, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow.uppercased())
                    .font(.quicksand(.medium, size: 12))
                    .tracking(2.00)
                    .foregroundStyle(FormSheetStyle.labelColor)
                Text(title)
                    .font(.quicksand(.medium, size: 22))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ServicePlanPalette.textMuted)
                    .frame(width: 32, height: 32)
                    .background(ServicePlanPalette.neutralChipBg)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ServicePlanPalette.borderLight)
                .frame(height: 0.75)
        }
    }

    private var saveArea: some View {
        Button(action: onSave) {
            Text(saveTitle)
                .font(.quicksand(.semibold, size: 14))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(canSave ? ServicePlanPalette.textPrimary : ServicePlanPalette.dotColor.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 32)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ServicePlanPalette.borderLight)
                .frame(height: 0.75)
        }
    }
}

/// Tracked caps label above content with a hairline underline.
struct FormSheetField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.quicksand(.medium, size: 10))
                .tracking(1.80)
                .foregroundStyle(FormSheetStyle.labelColor)
            content()
                .frame(height: 28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(FormSheetStyle.underline)
                        .frame(height: 0.75)
                }
        }
    }
}

/// Plain text field styled like the Log Service inputs.
struct FormSheetTextField: View {
    let placeholder: String
    @Binding var text: String
    var suffix: String? = nil
    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            TextField(placeholder, text: $text)
                .font(.quicksand(.regular, size: 17))
                .foregroundStyle(ServicePlanPalette.textPrimary)
                .keyboardType(keyboard)
                .textInputAutocapitalization(capitalization)
                .textFieldStyle(.plain)
            if let suffix {
                Text(suffix)
                    .font(.quicksand(.regular, size: 15))
                    .foregroundStyle(FormSheetStyle.labelColor)
            }
        }
    }
}

/// A tappable value that opens a menu of options, styled like a text input.
struct FormSheetMenuField<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    var body: some View {
        Menu {
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(label(option)).tag(option)
                }
            }
        } label: {
            HStack {
                Text(label(selection))
                    .font(.quicksand(.regular, size: 17))
                    .foregroundStyle(ServicePlanPalette.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ServicePlanPalette.dotColor)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Small grey helper text under a field group.
struct FormSheetHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.quicksand(.regular, size: 12))
            .foregroundStyle(FormSheetStyle.labelColor)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Adds thousands separators while typing a mileage ("47230" → "47,230").
func formattedMileageInput(_ text: String) -> String {
    let digits = text.filter(\.isNumber)
    guard let value = Int(digits), !digits.isEmpty else { return "" }
    return value.formatted()
}

/// Adds thousands separators while typing a dollar amount ("1234.5" → "1,234.5").
/// Keeps a trailing decimal point and at most two decimal places so typing isn't fought.
func formattedCostInput(_ text: String) -> String {
    let decimalSeparator = Locale.current.decimalSeparator ?? "."
    var whole = ""
    var fraction: String?
    for character in text {
        if character.isNumber {
            if fraction != nil {
                if fraction!.count < 2 { fraction!.append(character) }
            } else {
                whole.append(character)
            }
        } else if String(character) == decimalSeparator || character == ".", fraction == nil {
            fraction = ""
        }
    }
    // Drop leading zeros ("007" → "7") but keep a single "0" before a decimal.
    let trimmedWhole = String(whole.drop { $0 == "0" })
    var result = Int(trimmedWhole.prefix(9)).map { $0.formatted() } ?? (whole.isEmpty ? "" : "0")
    if let fraction {
        if result.isEmpty { result = "0" }
        result += decimalSeparator + fraction
    }
    return result
}

/// Reads a dollar amount typed with `formattedCostInput` ("1,234.50" → 1234.5).
func parsedCostInput(_ text: String) -> Double? {
    let decimalSeparator = Locale.current.decimalSeparator ?? "."
    let normalized = text
        .filter { $0.isNumber || String($0) == decimalSeparator }
        .replacingOccurrences(of: decimalSeparator, with: ".")
    return Double(normalized)
}
