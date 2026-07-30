import SwiftUI

struct TransfersV2View: View {

    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = TransfersV2ViewModel()

    @State private var rejectionTarget: TransferV2DTO?
    @State private var rejectionReason = ""
    @State private var quantityTarget: TransferV2DTO?
    @State private var quantityText = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.transfers.isEmpty {
                    ProgressView("Cargando transferencias…")
                } else if viewModel.transfers.isEmpty {
                    ContentUnavailableView(
                        "Sin transferencias",
                        systemImage: "shippingbox",
                        description: Text(
                            "Las transferencias asignadas aparecerán aquí."
                        )
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.transfers) { transfer in
                                transferCard(transfer)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle("Transferencias")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salir") {
                        Task {
                            await session.logout()
                        }
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .alert(
                "No se pudo completar",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: {
                        if !$0 {
                            viewModel.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $rejectionTarget) { transfer in
                rejectionSheet(transfer)
            }
            .sheet(item: $quantityTarget) { transfer in
                quantitySheet(transfer)
            }
        }
    }

    private func transferCard(
        _ transfer: TransferV2DTO
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(transfer.sku) · Talle \(transfer.size)")
                        .font(.headline)
                    Text(
                        "\(transfer.originBranch) → \(transfer.destinationBranch)"
                    )
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                }
                Spacer()
                Text(transfer.displayStatus)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(statusColor(transfer).opacity(0.14))
                    .foregroundColor(statusColor(transfer))
                    .clipShape(Capsule())
            }

            HStack(spacing: 20) {
                quantityLabel(
                    "Necesita",
                    transfer.neededQuantity
                )
                quantityLabel(
                    "Pedido",
                    transfer.operationalQuantity
                )
                if let received = transfer.receivedQuantity {
                    quantityLabel("Recibido", received)
                }
            }

            actionButtons(transfer)
        }
        .padding()
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12))
        }
        .opacity(
            viewModel.workingTransferID == transfer.id
                ? 0.55
                : 1
        )
        .disabled(viewModel.workingTransferID != nil)
    }

    @ViewBuilder
    private func actionButtons(
        _ transfer: TransferV2DTO
    ) -> some View {
        let role = session.user?.role
        let canOperate = role?.canApproveTransfers == true

        HStack {
            if transfer.status == "RECOMMENDED" && canOperate {
                operationButton("Aprobar", systemImage: "checkmark") {
                    await viewModel.approve(transfer)
                }
            }

            if transfer.status == "APPROVED" && canOperate {
                operationButton(
                    "Preparar",
                    systemImage: "shippingbox"
                ) {
                    await viewModel.prepare(transfer)
                }
            }

            if ["APPROVED", "PREPARING"].contains(transfer.status)
                && canOperate {
                operationButton(
                    "Despachar",
                    systemImage: "truck.box"
                ) {
                    await viewModel.dispatch(transfer)
                }
            }

            if transfer.status == "DISPATCHED"
                && (
                    role == .branchManager
                    || canOperate
                ) {
                operationButton(
                    "Recibido",
                    systemImage: "checkmark.circle"
                ) {
                    await viewModel.receive(transfer)
                }
            }

            if ["RECOMMENDED", "APPROVED", "PREPARING"]
                .contains(transfer.status) {
                Button("Rechazar", role: .destructive) {
                    rejectionReason = ""
                    rejectionTarget = transfer
                }
            }

            if canOperate
                && ["RECOMMENDED", "APPROVED", "PREPARING"]
                    .contains(transfer.status) {
                Button("Cantidad") {
                    quantityText = "\(transfer.operationalQuantity)"
                    quantityTarget = transfer
                }
            }
        }
        .font(.subheadline.weight(.semibold))
    }

    private func operationButton(
        _ title: String,
        systemImage: String,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task {
                await action()
            }
        } label: {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.blue)
    }

    private func quantityLabel(
        _ title: String,
        _ value: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
            Text("\(value)")
                .font(.headline)
        }
    }

    private func statusColor(
        _ transfer: TransferV2DTO
    ) -> Color {
        switch transfer.status {
        case "COMPLETED": return .green
        case "REJECTED": return .red
        case "DISPATCHED", "PARTIALLY_RECEIVED": return .orange
        default: return AppColors.blue
        }
    }

    private func rejectionSheet(
        _ transfer: TransferV2DTO
    ) -> some View {
        NavigationStack {
            Form {
                Section("Motivo obligatorio") {
                    TextField(
                        "Explicá por qué se rechaza",
                        text: $rejectionReason,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("Rechazar transferencia")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        rejectionTarget = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar") {
                        let reason = rejectionReason
                        rejectionTarget = nil
                        Task {
                            await viewModel.reject(
                                transfer,
                                reason: reason
                            )
                        }
                    }
                    .disabled(
                        rejectionReason.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
        }
    }

    private func quantitySheet(
        _ transfer: TransferV2DTO
    ) -> some View {
        NavigationStack {
            Form {
                Section("Nueva cantidad") {
                    TextField("Cantidad", text: $quantityText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Modificar cantidad")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        quantityTarget = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let quantity = Int(quantityText) ?? 0
                        quantityTarget = nil
                        Task {
                            await viewModel.updateQuantity(
                                transfer,
                                quantity: quantity
                            )
                        }
                    }
                    .disabled((Int(quantityText) ?? 0) <= 0)
                }
            }
        }
    }
}
