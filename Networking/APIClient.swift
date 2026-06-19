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

                throw NetworkError.serverError
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
}