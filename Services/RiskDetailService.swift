import Foundation

final class RiskDetailService {

    func fetchRiskDetail(
        riskKey: String
    ) async throws -> RiskDetailDTO {

        let encodedRiskKey = encodePathComponent(
            riskKey
        )

        var endpoint = "/risk-details/\(encodedRiskKey)"

        if let executionID = AppState.shared.selectedExecutionID {
            endpoint += "?execution_id=\(executionID)"
        }

        let response = try await APIClient.shared.fetch(
            endpoint: endpoint,
            responseType: RiskDetailAPIResponseDTO.self
        )

        return response.data
    }

    func addRecommendationToF8(
        riskKey: String
    ) async throws -> RiskActionStatusResponseDTO {

        if AppState.shared.isHistoricalMode {
            throw RiskDetailUserError.historicalMode
        }

        let encodedRiskKey = encodePathComponent(
            riskKey
        )

        return try await APIClient.shared.post(
            endpoint: "/alert-actions/recommendation/\(encodedRiskKey)/add-to-f8",
            body: EmptyBodyDTO(),
            responseType: RiskActionStatusResponseDTO.self
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

enum RiskDetailUserError: LocalizedError {

    case historicalMode
    case alreadyAdded
    case notActionable

    var errorDescription: String? {

        switch self {

        case .historicalMode:
            return "No se puede modificar el F8 desde el modo histórico."

        case .alreadyAdded:
            return "Este producto ya fue agregado al F8."

        case .notActionable:
            return "Esta recomendación no se puede agregar al F8."
        }
    }
}