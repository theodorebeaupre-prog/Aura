import SwiftUI

struct SettingsRowView: View {
    let setting: SystemSetting
    @Binding var pendingValue: SettingValue?

    private var effectiveValue: SettingValue { pendingValue ?? setting.value }
    private var isModified: Bool { pendingValue != nil && pendingValue != setting.value }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(setting.key)
                        .font(.callout)
                    if isModified {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                    }
                }
                Text(setting.domain)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            controlView
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var controlView: some View {
        switch effectiveValue {
        case .bool(let b):
            Toggle("", isOn: Binding(
                get: { b },
                set: { newVal in
                    if case .bool(let orig) = setting.value, newVal == orig {
                        pendingValue = nil
                    } else {
                        pendingValue = .bool(newVal)
                    }
                }
            ))
            .labelsHidden()

        case .double(let d):
            HStack(spacing: 8) {
                if isModified, case .double(let orig) = setting.value {
                    Text(String(format: "%.2f", orig))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
                Slider(
                    value: Binding(
                        get: { d },
                        set: { newVal in
                            if case .double(let orig) = setting.value, abs(newVal - orig) < 0.001 {
                                pendingValue = nil
                            } else {
                                pendingValue = .double(newVal)
                            }
                        }
                    ),
                    in: doubleRange(for: d)
                )
                .frame(width: 120)
                Text(String(format: "%.2f", d))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }

        case .int(let i):
            HStack(spacing: 8) {
                if isModified, case .int(let orig) = setting.value {
                    Text("\(orig)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
                Stepper(
                    value: Binding(
                        get: { i },
                        set: { newVal in
                            if case .int(let orig) = setting.value, newVal == orig {
                                pendingValue = nil
                            } else {
                                pendingValue = .int(newVal)
                            }
                        }
                    ),
                    in: intRange(for: i)
                ) {
                    Text("\(i)")
                        .font(.callout.monospacedDigit())
                        .frame(width: 36, alignment: .trailing)
                }
            }

        case .string(let s):
            HStack(spacing: 8) {
                if isModified, case .string(let orig) = setting.value {
                    Text(orig)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
                TextField("Value", text: Binding(
                    get: { s },
                    set: { newVal in
                        if case .string(let orig) = setting.value, newVal == orig {
                            pendingValue = nil
                        } else {
                            pendingValue = .string(newVal)
                        }
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 130)
            }
        }
    }

    private func doubleRange(for value: Double) -> ClosedRange<Double> {
        if value <= 0 { return 0.0...1.0 }
        if value <= 1.0 { return 0.0...1.0 }
        if value <= 10.0 { return 0.0...10.0 }
        return 0.0...max(200.0, value * 2)
    }

    private func intRange(for value: Int) -> ClosedRange<Int> {
        0...max(100, value * 2)
    }
}
