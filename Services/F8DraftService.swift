import Foundation

final class F8DraftService {

    func fetchLatestDraft() async throws -> F8DraftDTO {

        let response: F8DraftAPIResponseDTO = try await request(
            endpoint: "/f8-drafts/latest",
            method: "GET"
        )

        return response.data
    }

    func fetchDraft(
        draftID: Int
    ) async throws -> F8DraftDTO {

        let response: F8DraftAPIResponseDTO = try await request(
            endpoint: "/f8-drafts/\(draftID)",
            method: "GET"
        )

        return response.data
    }

    func fetchValidation(
        draftID: Int
    ) async throws -> F8DraftValidationDTO {

        let response: F8DraftValidationAPIResponseDTO = try await request(
            endpoint: "/f8-drafts/\(draftID)/validation",
            method: "GET"
        )

        return response.data
    }

    func fetchRowOptions(
        draftID: Int,
        rowID: Int
    ) async throws -> F8DraftRowOptionsDTO {

        let response: F8DraftRowOptionsAPIResponseDTO = try await request(
            endpoint: "/f8-drafts/\(draftID)/rows/\(rowID)/options",
            method: "GET"
        )

        return response.data
    }

    func updateRow(
        draftID: Int,
        rowID: Int,
        body: F8DraftRowUpdateRequestDTO
    ) async throws -> F8DraftDTO {

        let response: F8DraftAPIResponseDTO = try await request(
            endpoint: "/f8-drafts/\(draftID)/rows/\(rowID)",
            method: "PUT",
            body: body
        )

        return response.data
    }

    func deleteRow(
        draftID: Int,
        rowID: Int
    ) async throws -> F8DraftDTO {

        let response: F8DraftAPIResponseDTO = try await request(
            endpoint: "/f8-drafts/\(draftID)/rows/\(rowID)",
            method: "DELETE"
        )

        return response.data
    }

    func confirmDraft(
        draftID: Int
    ) async throws -> F8DraftDTO {

        let response: F8DraftAPIResponseDTO = try await request(
            endpoint: "/f8-drafts/\(draftID)/confirm",
            method: "POST"
        )

        return response.data
    }

    func downloadConfirmedFile(
        draft: F8DraftDTO
    ) async throws -> URL {

        guard let fileName = draft.finalReportFileName else {
            throw F8DraftServiceError.noConfirmedFile
        }

        let encodedFileName = encodePathComponent(
            fileName
        )

        guard let url = URL(
            string: Environment.baseURL + "/reports/\(encodedFileName)/download"
        ) else {
            throw NetworkError.invalidURL
        }

        let (
            data,
            response
        ) = try await URLSession.shared.data(
            from: url
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw F8DraftServiceError.serverMessage(
                "No se pudo descargar el F8 confirmado."
            )
        }

        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        if FileManager.default.fileExists(
            atPath: localURL.path
        ) {
            try FileManager.default.removeItem(
                at: localURL
            )
        }

        try data.write(
            to: localURL
        )

        return localURL
    }

    private func request<T: Decodable>(
        endpoint: String,
        method: String
    ) async throws -> T {

        guard let url = URL(
            string: Environment.baseURL + endpoint
        ) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(
            url: url
        )

        request.httpMethod = method

        let (
            data,
            response
        ) = try await URLSession.shared.data(
            for: request
        )

        return try decodeResponse(
            data: data,
            response: response
        )
    }

    private func request<T: Decodable, Body: Encodable>(
        endpoint: String,
        method: String,
        body: Body
    ) async throws -> T {

        guard let url = URL(
            string: Environment.baseURL + endpoint
        ) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(
            url: url
        )

        request.httpMethod = method

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = try JSONEncoder().encode(
            body
        )

        let (
            data,
            response
        ) = try await URLSession.shared.data(
            for: request
        )

        return try decodeResponse(
            data: data,
            response: response
        )
    }

    private func decodeResponse<T: Decodable>(
        data: Data,
        response: URLResponse
    ) throws -> T {

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {

            if let serverError = try? JSONDecoder().decode(
                F8ServerErrorDTO.self,
                from: data
            ),
            let detail = serverError.detail {

                throw F8DraftServiceError.serverMessage(
                    detail
                )
            }

            if httpResponse.statusCode == 404 {
                throw F8DraftServiceError.serverMessage(
                    "No hay F8 borrador disponible."
                )
            }

            if httpResponse.statusCode == 409 {
                throw F8DraftServiceError.serverMessage(
                    "No se pudo validar la operación del F8."
                )
            }

            throw NetworkError.serverError
        }

        return try JSONDecoder().decode(
            T.self,
            from: data
        )
    }

    private func encodePathComponent(
        _ value: String
    ) -> String {

        var allowed = CharacterSet.urlPathAllowed

        allowed.remove(
            charactersIn: "/?#[]@!$&'()*+,;="
        )

        return value.addingPercentEncoding(
            withAllowedCharacters: allowed
        ) ?? value
    }
}

enum F8DraftServiceError: LocalizedError {

    case noConfirmedFile
    case serverMessage(String)

    var errorDescription: String? {

        switch self {

        case .noConfirmedFile:
            return "El F8 todavía no tiene archivo confirmado."

        case .serverMessage(let message):
            return message
        }
    }
}