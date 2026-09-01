import Foundation

public enum VietnameseInputMethod: String, CaseIterable, Sendable {
    case telex
    case vni
}

public enum VietnameseConverter {
  public static func convert(_ text: String, method: VietnameseInputMethod = .telex) -> String {
        switch method {
        case .telex:
            return TelexEngine.transform(text)
        case .vni:
            return VNIEngine.transform(text)
        }
    }
}
