import Foundation

enum AppTab: String, Identifiable {

    case home
    case alerts
    case transfers
    case users
    case activity
    case branches
    case replenishment
    case reports

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .home: return "Inicio"
        case .alerts: return "Alertas"
        case .transfers: return "Envíos"
        case .users: return "Usuarios"
        case .activity: return "Actividad"
        case .branches: return "Sucursales"
        case .replenishment: return "Reposición"
        case .reports: return "Reportes"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .alerts: return "bell"
        case .transfers: return "arrow.left.arrow.right"
        case .users: return "person.2"
        case .activity: return "clock.arrow.circlepath"
        case .branches: return "building.2"
        case .replenishment: return "arrow.triangle.2.circlepath"
        case .reports: return "doc.text"
        }
    }
}
