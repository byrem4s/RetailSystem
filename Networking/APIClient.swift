import Foundation

final class APIClient {

    static let shared = APIClient()

    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    func fetch<T: Decodable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        try await execute(
            endpoint: endpoint,
            method: "GET",
            body: nil,
            responseType: responseType
        )
    }

    func post<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body,
        responseType: T.Type
    ) async throws -> T {
        try await execute(
            endpoint: endpoint,
            method: "POST",
            body: try JSONEncoder().encode(body),
            responseType: responseType
        )
    }

    func post<T: Decodable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        try await execute(
            endpoint: endpoint,
            method: "POST",
            body: nil,
            responseType: responseType
        )
    }

    func put<T: Decodable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        try await execute(
            endpoint: endpoint,
            method: "PUT",
            body: nil,
            responseType: responseType
        )
    }

    func put<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body,
        responseType: T.Type
    ) async throws -> T {
        try await execute(
            endpoint: endpoint,
            method: "PUT",
            body: try JSONEncoder().encode(body),
            responseType: responseType
        )
    }

    func delete<T: Decodable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        try await execute(
            endpoint: endpoint,
            method: "DELETE",
            body: nil,
            responseType: responseType
        )
    }

    func executePatch<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body,
        responseType: T.Type
    ) async throws -> T {
        try await execute(
            endpoint: endpoint,
            method: "PATCH",
            body: try JSONEncoder().encode(body),
            responseType: responseType
        )
    }

    func send<Body: Encodable>(
        endpoint: String,
        method: String,
        body: Body
    ) async throws {
        let request = try makeRequest(
            endpoint: endpoint,
            method: method,
            body: try JSONEncoder().encode(body)
        )
        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
    }

    func makeURL(endpoint: String) throws -> URL {
        guard let url = URL(
            string: Environment.baseURL + endpoint
        ) else {
            throw NetworkError.invalidURL
        }
        return url
    }

    func authorize(_ request: inout URLRequest) {
        guard let token = SecureTokenStore.shared.accessToken,
              !token.isEmpty else {
            return
        }
        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )
    }

    private func execute<T: Decodable>(
        endpoint: String,
        method: String,
        body: Data?,
        responseType: T.Type
    ) async throws -> T {
        let request = try makeRequest(
            endpoint: endpoint,
            method: method,
            body: body
        )
        do {
            let (data, response) = try await session.data(for: request)
            try validate(data: data, response: response)
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError
            }
        } catch let error as URLError where error.code == .timedOut {
            throw NetworkError.timeout
        }
    }

    private func makeRequest(
        endpoint: String,
        method: String,
        body: Data?
    ) throws -> URLRequest {
        let url = try makeURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )
        if let body {
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.httpBody = body
        }
        authorize(&request)
        return request
    }

    private func validate(
        data: Data,
        response: URLResponse
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard 200...299 ~= httpResponse.statusCode else {
            if httpResponse.statusCode == 401 {
                NotificationCenter.default.post(
                    name: .sessionUnauthorized,
                    object: nil
                )
            }
            throw serverError(
                from: data,
                statusCode: httpResponse.statusCode
            )
        }
    }

    private func serverError(
        from data: Data,
        statusCode: Int
    ) -> NetworkError {
        if let errorResponse = try? JSONDecoder().decode(
            APIErrorResponseDTO.self,
            from: data
        ) {
            let message = errorResponse.detail ?? errorResponse.message
            if let message,
               !message.trimmingCharacters(
                    in: .whitespacesAndNewlines
               ).isEmpty {
                return .serverMessage(message)
            }
        }
        if statusCode == 409 {
            return .serverMessage(
                "Los datos cambiaron. Actualizá la pantalla antes de continuar."
            )
        }
        return .serverError
    }
}

extension Notification.Name {
    static let sessionUnauthorized = Notification.Name(
        "sessionUnauthorized"
    )
}

private struct APIErrorResponseDTO: Decodable {
    let detail: String?
    let message: String?
}
