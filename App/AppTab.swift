import Foundation

enum AppTab: String, Identifiable, CaseIterable {
    case home
    case replenishment
    case transfers
    case management
    case reports

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Inicio"
        case .replenishment: return "Reposición"
        case .transfers: return "Envíos"
        case .management: return "Gestión"
        case .reports: return "Historial"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .replenishment: return "arrow.triangle.2.circlepath"
        case .transfers: return "shippingbox"
        case .management: return "person.2"
        case .reports: return "clock.arrow.circlepath"
        }
    }
}
