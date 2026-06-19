import Foundation

enum NetworkError: LocalizedError {

    case invalidURL

    case invalidResponse

    case serverError

    case decodingError

    case timeout

    var errorDescription: String? {

        switch self {

        case .invalidURL:
            return "URL inválida"

        case .invalidResponse:
            return "Respuesta inválida"

        case .serverError:
            return "Error del servidor"

        case .decodingError:
            return "Error procesando datos"

        case .timeout:
            return "Tiempo de espera agotado"
        }
    }
}