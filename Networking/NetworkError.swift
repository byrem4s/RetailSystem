import Foundation

enum NetworkError: LocalizedError {

    case invalidURL

    case invalidResponse

    case serverError

    case serverMessage(String)

    case decodingError

    case timeout

    case connectionUnavailable

    case localConnectionBlocked

    var errorDescription: String? {

        switch self {

        case .invalidURL:
            return "URL inválida"

        case .invalidResponse:
            return "Respuesta inválida"

        case .serverError:
            return "Error del servidor"

        case .serverMessage(let message):
            return message

        case .decodingError:
            return "Error procesando datos"

        case .timeout:
            return "El servidor no respondió. Verificá que el iPhone y la PC estén en la misma red y que el puerto 8080 esté habilitado."

        case .connectionUnavailable:
            return "No se pudo conectar con el servidor local. Revisá el permiso de Red local del iPhone y el firewall de Windows."

        case .localConnectionBlocked:
            return "iOS bloqueó la conexión HTTP local. Volvé a instalar la app para aplicar su configuración de red."
        }
    }
}
