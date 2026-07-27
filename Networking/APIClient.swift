import Foundation

final class APIClient {

    static let shared = APIClient()

    private init() {}

    private let baseURL =
        Environment.baseURL

    private let session: URLSession = {

        let config = URLSessionConfiguration.default

        config.timeoutIntervalForRequest = 15

        config.timeoutIntervalForResource = 30

        return URLSession(
            configuration: config
        )
    }()

    func fetch<T: Decodable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {

        guard let url = URL(
            string: baseURL + endpoint
        ) else {

            throw NetworkError.invalidURL
        }

        do {

            let (data, response) = try await session.data(
                from: url
            )

            guard let httpResponse = response as? HTTPURLResponse else {

                throw NetworkError.invalidResponse
            }

            guard 200...299 ~= httpResponse.statusCode else {

                throw serverError(
                    from: data,
                    statusCode: httpResponse.statusCode
                )
            }

            do {

                let decoded = try JSONDecoder().decode(
                    T.self,
                    from: data
                )

                return decoded

            } catch {

                throw NetworkError.decodingError
            }

        } catch {

            if let error = error as? URLError {

                if error.code == .timedOut {

                    throw NetworkError.timeout
                }
            }

            throw error
        }
    }

    func post<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body,
        responseType: T.Type
    ) async throws -> T {

        guard let url = URL(
            string: baseURL + endpoint
        ) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(
            url: url
        )

        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = try JSONEncoder().encode(
            body
        )

        do {

            let (data, response) = try await session.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw serverError(
                    from: data,
                    statusCode: httpResponse.statusCode
                )
            }

            do {

                return try JSONDecoder().decode(
                    T.self,
                    from: data
                )

            } catch {
                throw NetworkError.decodingError
            }

        } catch {

            if let error = error as? URLError,
            error.code == .timedOut {
                throw NetworkError.timeout
            }

            throw error
        }
    }

    func makeURL(
        endpoint: String
    ) throws -> URL {

        guard let url = URL(
            string: baseURL + endpoint
        ) else {
            throw NetworkError.invalidURL
        }

        return url
    }

    func put<T: Decodable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {

        guard let url = URL(
            string: baseURL + endpoint
        ) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(
            url: url
        )

        request.httpMethod = "PUT"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        do {

            let (data, response) = try await session.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw serverError(
                    from: data,
                    statusCode: httpResponse.statusCode
                )
            }

            do {

                return try JSONDecoder().decode(
                    T.self,
                    from: data
                )

            } catch {

                throw NetworkError.decodingError
            }

        } catch {

            if let error = error as? URLError,
            error.code == .timedOut {
                throw NetworkError.timeout
            }

            throw error
        }
    }

    func put<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body,
        responseType: T.Type
    ) async throws -> T {

        guard let url = URL(
            string: baseURL + endpoint
        ) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(
            url: url
        )

        request.httpMethod = "PUT"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = try JSONEncoder().encode(
            body
        )

        do {

            let (data, response) = try await session.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw serverError(
                    from: data,
                    statusCode: httpResponse.statusCode
                )
            }

            do {

                return try JSONDecoder().decode(
                    T.self,
                    from: data
                )

            } catch {

                throw NetworkError.decodingError
            }

        } catch {

            if let error = error as? URLError,
            error.code == .timedOut {
                throw NetworkError.timeout
            }

            throw error
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

            let message = errorResponse.detail
            ?? errorResponse.message

            if let message,
               !message.trimmingCharacters(
                    in: .whitespacesAndNewlines
               ).isEmpty {

                return .serverMessage(message)
            }
        }

        if statusCode == 409 {
            return .serverMessage(
                "La operación no pudo completarse porque los datos cambiaron o la acción ya no es válida."
            )
        }

        return .serverError
    }
}

private struct APIErrorResponseDTO: Decodable {

    let detail: String?
    let message: String?
}
