import Foundation

extension SettingValue {
    var displayString: String {
        switch self {
        case .bool(let b):   return b ? "On" : "Off"
        case .int(let i):    return "\(i)"
        case .double(let d): return String(format: "%.2f", d)
        case .string(let s): return s
        }
    }
}
