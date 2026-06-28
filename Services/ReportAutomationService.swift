import Foundation

final class ReportAutomationService {

    func fetchConfig() async throws -> ReportAutomationConfigDTO {

        let response = try await APIClient.shared.fetch(
            endpoint: "/report-automation/config",
            responseType: ReportAutomationConfigAPIResponseDTO.self
        )

        return response.data
    }

    func updateConfig(
        payload: ReportAutomationConfigUpdateDTO
    ) async throws -> ReportAutomationConfigDTO {

        let response = try await APIClient.shared.put(
            endpoint: "/report-automation/config",
            body: payload,
            responseType: ReportAutomationConfigAPIResponseDTO.self
        )

        return response.data
    }

    func runNow() async throws -> ReportAutomationRunDTO {

        let response = try await APIClient.shared.post(
            endpoint: "/report-automation/run-now",
            body: EmptyBodyDTO(),
            responseType: ReportAutomationRunNowAPIResponseDTO.self
        )

        return response.data.run
    }

    func fetchRuns() async throws -> [ReportAutomationRunDTO] {

        let response = try await APIClient.shared.fetch(
            endpoint: "/report-automation/runs",
            responseType: ReportAutomationRunsAPIResponseDTO.self
        )

        return response.data.runs
    }
}