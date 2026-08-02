import SwiftUI

struct TransfersV2View: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = TransfersV2ViewModel()

    @State private var filter: TransferFilter = .active
    @State private var rejectionTarget: TransferV2DTO?
    @State private var rejectionReason = ""
    @State private var quantityTarget: TransferV2DTO?
    @State private var quantityText = ""

    private enum TransferFilter: String, Identifiable {
        case active = "Activos"
        case prepare = "Preparar"
        case receive = "Recibir"
        case closed = "Cerrados"

        var id: String { rawValue }
    }

    private var isBranchManager: Bool {
        session.user?.role == .branchManager
    }

    private var filters: [TransferFilter] {
        isBranchManager
            ? [.prepare, .receive, .closed]
            : [.active, .closed]
    }

    var body: some View {
        NavigationStack {
            ResponsiveScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    PageHeading(
                        eyebrow: isBranchManager
                            ? "Mi sucursal"
                            : "Logística",
                        title: "Envíos",
                        subtitle: isBranchManager
                            ? (
                                "Separá lo que tu sucursal debe entregar y "
                                + "confirmá únicamente lo que recibe."
                            )
                            : (
                                "Aprobá recomendaciones, coordiná la "
                                + "preparación y cerrá cada movimiento."
                            )
                    )

                    Picker("Vista", selection: $filter) {
                        ForEach(filters) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    transferContent
                }
            }
            .navigationTitle("Envíos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel("Actualizar envíos")
                }
            }
            .task {
                if isBranchManager && filter == .active {
                    filter = .prepare
                }
                await viewModel.load()
            }
            .refreshable { await viewModel.load() }
            .alert(
                "No se pudo completar",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
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

    @ViewBuilder
    private var transferContent: some View {
        if viewModel.isLoading && viewModel.transfers.isEmpty {
            ProgressView("Cargando movimientos…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.section)
        } else if filteredTransfers.isEmpty {
            AppCard {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "shippingbox",
                    description: Text(emptyMessage)
                )
            }
        } else {
            HStack {
                Text("\(filteredTransfers.count) movimientos")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)
                Spacer()
            }

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 300), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(filteredTransfers) { transfer in
                    transferCard(transfer)
                }
            }
        }
    }

    private func transferCard(_ transfer: TransferV2DTO) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.regular) {
                HStack(alignment: .top) {
                    IconBadge(
                        systemName: relationshipIcon(transfer),
                        color: statusColor(transfer)
                    )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(relationshipLabel(transfer))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(statusColor(transfer))
                        Text(transfer.sku)
                            .font(AppTypography.cardTitle)
                        Text("Talle \(transfer.size)")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    Spacer()
                    StatusPill(
                        title: contextualStatus(transfer),
                        color: statusColor(transfer)
                    )
                }

                routeView(transfer)

                HStack(spacing: AppSpacing.large) {
                    quantityLabel("Necesita", transfer.neededQuantity)
                    quantityLabel("Movimiento", transfer.operationalQuantity)
                    if let received = transfer.receivedQuantity {
                        quantityLabel("Recibido", received)
                    }
                }

                actionButtons(transfer)
            }
            .opacity(
                viewModel.workingTransferID == transfer.id ? 0.55 : 1
            )
            .disabled(viewModel.workingTransferID != nil)
        }
    }

    private func routeView(_ transfer: TransferV2DTO) -> some View {
        HStack(spacing: AppSpacing.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ORIGEN")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(AppColors.tertiaryText)
                Text(transfer.originBranch)
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
            Image(systemName: "arrow.right")
                .foregroundStyle(AppColors.blue)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("DESTINO")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(AppColors.tertiaryText)
                Text(transfer.destinationBranch)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.field)
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppSpacing.controlRadius,
                style: .continuous
            )
        )
    }

    @ViewBuilder
    private func actionButtons(_ transfer: TransferV2DTO) -> some View {
        let role = session.user?.role
        let canOperate = role?.canApproveTransfers == true
        let branchID = session.user?.branchID
        let isDestination = branchID == transfer.destinationBranchID
        let isOwnTransfer = branchID == transfer.originBranchID
            || isDestination

        if canOperate || isOwnTransfer {
            Divider()
            HStack(spacing: AppSpacing.small) {
                if transfer.status == "RECOMMENDED" && canOperate {
                    operationButton(
                        "Aprobar",
                        systemImage: "checkmark"
                    ) {
                        await viewModel.approve(transfer)
                    }
                }

                if transfer.status == "APPROVED" && canOperate {
                    operationButton(
                        "Iniciar",
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

                if ["DISPATCHED", "PARTIALLY_RECEIVED"]
                    .contains(transfer.status)
                    && (canOperate || isDestination) {
                    operationButton(
                        "Confirmar recepción",
                        systemImage: "checkmark.circle"
                    ) {
                        await viewModel.receive(transfer)
                    }
                }

                if ["RECOMMENDED", "APPROVED", "PREPARING"]
                    .contains(transfer.status) {
                    Menu {
                        if canOperate {
                            Button {
                                quantityText = "\(transfer.operationalQuantity)"
                                quantityTarget = transfer
                            } label: {
                                Label(
                                    "Modificar cantidad",
                                    systemImage: "number"
                                )
                            }
                        }
                        Button(role: .destructive) {
                            rejectionReason = ""
                            rejectionTarget = transfer
                        } label: {
                            Label(
                                "Rechazar movimiento",
                                systemImage: "xmark.circle"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.headline)
                            .frame(width: 42, height: 42)
                            .background(AppColors.elevated)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func operationButton(
        _ title: String,
        systemImage: String,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.blue)
    }

    private func quantityLabel(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppColors.secondaryText)
            Text("\(value)")
                .font(.headline)
        }
    }

    private var filteredTransfers: [TransferV2DTO] {
        let branchID = session.user?.branchID
        switch filter {
        case .active:
            return viewModel.transfers.filter { !isClosed($0) }
        case .prepare:
            return viewModel.transfers.filter {
                $0.originBranchID == branchID && !isClosed($0)
            }
        case .receive:
            return viewModel.transfers.filter {
                $0.destinationBranchID == branchID
                    && !isClosed($0)
            }
        case .closed:
            return viewModel.transfers.filter(isClosed)
        }
    }

    private func isClosed(_ transfer: TransferV2DTO) -> Bool {
        ["COMPLETED", "REJECTED"].contains(transfer.status)
    }

    private var emptyTitle: String {
        switch filter {
        case .prepare: return "Nada para preparar"
        case .receive: return "Nada para recibir"
        case .closed: return "Sin movimientos cerrados"
        case .active: return "Sin movimientos activos"
        }
    }

    private var emptyMessage: String {
        switch filter {
        case .prepare:
            return "Cuando se distribuya un F8, verás aquí lo que sale de tu sucursal."
        case .receive:
            return "Los productos aparecerán cuando se distribuya el F8, aunque todavía no hayan sido despachados."
        case .closed:
            return "Todavía no hay movimientos completados o rechazados."
        case .active:
            return "Los movimientos creados al distribuir un F8 aparecerán aquí."
        }
    }

    private func relationshipLabel(_ transfer: TransferV2DTO) -> String {
        guard let branchID = session.user?.branchID else {
            return "MOVIMIENTO"
        }
        if transfer.originBranchID == branchID {
            return "TENÉS QUE PREPARAR"
        }
        if transfer.destinationBranchID == branchID {
            return "VAS A RECIBIR"
        }
        return "MOVIMIENTO"
    }

    private func contextualStatus(_ transfer: TransferV2DTO) -> String {
        guard transfer.destinationBranchID == session.user?.branchID else {
            return transfer.displayStatus
        }
        switch transfer.status {
        case "RECOMMENDED", "APPROVED", "PREPARING":
            return "Esperando envío"
        case "DISPATCHED", "PARTIALLY_RECEIVED":
            return "En proceso"
        case "COMPLETED":
            return "Recibido"
        case "REJECTED":
            return "Cancelado"
        default:
            return transfer.displayStatus
        }
    }

    private func relationshipIcon(_ transfer: TransferV2DTO) -> String {
        guard let branchID = session.user?.branchID else {
            return "arrow.left.arrow.right"
        }
        return transfer.originBranchID == branchID
            ? "shippingbox"
            : "tray.and.arrow.down"
    }

    private func statusColor(_ transfer: TransferV2DTO) -> Color {
        switch transfer.status {
        case "COMPLETED": return AppColors.green
        case "REJECTED": return AppColors.red
        case "DISPATCHED", "PARTIALLY_RECEIVED": return AppColors.orange
        case "PREPARING": return AppColors.purple
        default: return AppColors.blue
        }
    }

    private func rejectionSheet(
        _ transfer: TransferV2DTO
    ) -> some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "Explicá por qué se rechaza",
                        text: $rejectionReason,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                } header: {
                    Text("Motivo obligatorio")
                } footer: {
                    Text(
                        "La decisión quedará registrada en el historial "
                        + "del movimiento."
                    )
                }
            }
            .navigationTitle("Rechazar movimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { rejectionTarget = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar", role: .destructive) {
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
                        rejectionReason
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
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
                Section {
                    LabeledContent(
                        "Necesidad calculada",
                        value: "\(transfer.neededQuantity)"
                    )
                }
            }
            .navigationTitle("Modificar cantidad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { quantityTarget = nil }
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
