import Foundation

enum Weekday: Int, CaseIterable, Identifiable, Codable {
    case mon = 1, tue, wed, thu, fri, sat, sun
    
    var id: Int { rawValue }
    
    var short: String {
        switch Locale.current.language.languageCode?.identifier {
        case "uk":
            switch self {
            case .mon: return "Пн"
            case .tue: return "Вт"
            case .wed: return "Ср"
            case .thu: return "Чт"
            case .fri: return "Пт"
            case .sat: return "Сб"
            case .sun: return "Нд"
            }
        default:
            switch self {
            case .mon: return "Mon"
            case .tue: return "Tue"
            case .wed: return "Wed"
            case .thu: return "Thu"
            case .fri: return "Fri"
            case .sat: return "Sat"
            case .sun: return "Sun"
            }
        }
    }
}
