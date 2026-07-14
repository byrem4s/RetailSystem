import Foundation
import Combine

@MainActor
final class F8DraftViewModel: ObservableObject {

    @Published var draft: F8DraftDTO?
    @Published var validation: F8DraftValidationDTO?
    @Published var selectedRowOptions: F8DraftRowOptionsDTO?

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isConfirming = false
    @Published var isDownloading = false

    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var editingRow: F8DraftRowDTO?

    private let service = F8DraftService()

    var rows: [F8DraftRowDTO] {
        draft?.rows ?? []
    }

    var canConfirm: Bool {

        guard let draft else {
            return false
        }

        if draft.isConfirmed {
            return false
        }

        if rows.isEmpty {
            return false
        }

        return validation?.canConfirm ?? true
    }

    var statusText: String {

        guard let draft else {
            return "Sin F8"
        }

        return draft.displayStatus
    }

    func loadLatestDraft() async {

        isLoading = true
        errorMessage = nil

        do {

            draft = try await service.fetchLatestDraft()

            if let draft {
                await loadValidation(
                    draftID: draft.id
                )
            }

        } catch {

            draft = nil
            validation = nil
            errorMessage = friendlyError(
                error
            )
        }

        isLoading = false
    }

    func refreshCurrentDraft() async {

        guard let draft else {
            await loadLatestDraft()
            return
        }

        await loadDraft(
            draftID: draft.id
        )
    }

    func loadDraft(
        draftID: Int
    ) async {

        isLoading = true
        errorMessage = nil

        do {

            draft = try await service.fetchDraft(
                draftID: draftID
            )

            await loadValidation(
                draftID: draftID
            )

        } catch {

            errorMessage = friendlyError(
                error
            )
        }

        isLoading = false
    }

    func loadValidation(
        draftID: Int
    ) async {

        do {

            validation = try await service.fetchValidation(
                draftID: draftID
            )

        } catch {

            validation = nil
        }
    }

    func loadOptions(
        row: F8DraftRowDTO
    ) async {

        guard let draft else {
            return
        }

        selectedRowOptions = nil

        do {

            selectedRowOptions = try await service.fetchRowOptions(
                draftID: draft.id,
                rowID: row.id
            )

        } catch {

            errorMessage = friendlyError(
                error
            )
        }
    }

    func updateRow(
        row: F8DraftRowDTO,
        origin: String,
        destination: String,
        size: String,
        quantity: Int
    ) async -> Bool {

        guard let draft else {
            errorMessage = "No hay F8 borrador disponible."
            return false
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {

            let body = F8DraftRowUpdateRequestDTO(
                origin: origin,
                destination: destination,
                size: size,
                quantity: quantity
            )

            self.draft = try await service.updateRow(
                draftID: draft.id,
                rowID: row.id,
                body: body
            )

            await loadValidation(
                draftID: draft.id
            )

            successMessage = "Fila actualizada correctamente."
            editingRow = nil

            AppState.shared.refreshSystem()

            isSaving = false
            return true

        } catch {

            errorMessage = friendlyError(
                error
            )

            isSaving = false
            return false
        }
    }

    func deleteRow(
        row: F8DraftRowDTO
    ) async {

        guard let draft else {
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {

            self.draft = try await service.deleteRow(
                draftID: draft.id,
                rowID: row.id
            )

            await loadValidation(
                draftID: draft.id
            )

            successMessage = "Fila eliminada del F8."

            AppState.shared.refreshSystem()

        } catch {

            errorMessage = friendlyError(
                error
            )
        }

        isSaving = false
    }

    func confirmDraft() async {

        guard let draft else {
            errorMessage = "No hay F8 borrador disponible."
            return
        }

        isConfirming = true
        errorMessage = nil
        successMessage = nil

        do {

            self.draft = try await service.confirmDraft(
                draftID: draft.id
            )

            await loadValidation(
                draftID: draft.id
            )

            successMessage = "F8 confirmado correctamente."

            AppState.shared.refreshSystem()

        } catch {

            errorMessage = friendlyError(
                error
            )
        }

        isConfirming = false
    }

    func downloadConfirmedFile() async -> URL? {

        guard let draft else {
            errorMessage = "No hay F8 disponible."
            return nil
        }

        isDownloading = true
        errorMessage = nil

        do {

            let url = try await service.downloadConfirmedFile(
                draft: draft
            )

            isDownloading = false
            return url

        } catch {

            errorMessage = friendlyError(
                error
            )

            isDownloading = false
            return nil
        }
    }

    func validationForRow(
        _ row: F8DraftRowDTO
    ) -> F8DraftRowValidationDTO? {

        validation?.rows.first {
            $0.rowID == row.id
        }
    }

    private func friendlyError(
        _ error: Error
    ) -> String {

        let message = error.localizedDescription

        if message.lowercased().contains("stock") {
            return message
        }

        if message.lowercased().contains("origen") {
            return message
        }

        if message.lowercased().contains("duplic") ||
            message.lowercased().contains("ya existe") {
            return "Ya existe una fila igual en este F8."
        }

        return message
    }
}