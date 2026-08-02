import SwiftUI

struct TransfersV2View: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = TransfersV2ViewModel()

    @State private var filter: TransferFilter = .active
    @State private var rejectionTarget: TransferV2DTO?
    @State private var rejectionReason = ""
    @State private var quantityTarget: TransferV2DTO?
    @State private var quantityText = ""
    @State private var showsCustomerRequest = false

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

    private var canRequestProduct: Bool {
        session.user?.role == .branchManager
            || session.user?.role == .warehouse
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
                if canRequestProduct {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showsCustomerRequest = true
                            Task {
                                await viewModel.loadCustomerRequestOptions()
                            }
                        } label: {
                            Label("Pedir producto", systemImage: "plus")
                        }
                    }
                }
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
            .sheet(isPresented: $showsCustomerRequest) {
                CustomerProductRequestView(
                    options: viewModel.customerRequestOptions,
                    destinationBranchID: session.user?.branchID,
                    isLoading: viewModel.isLoading,
                    onSave: { option, quantity, note in
                        await viewModel.createCustomerRequest(
                            option: option,
                            destinationBranchID: session.user?.branchID,
                            quantity: quantity,
                            note: note
                        )
                    }
                )
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
                        if transfer.transferType == "CUSTOMER_REQUEST" {
                            Text("PEDIDO PARA VENTA INMEDIATA")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppColors.purple)
                        }
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

                if let estimated = transfer.estimatedDeliveryDate {
                    Label(
                        "Llegada estimada: \(displayDate(estimated))",
                        systemImage: "calendar.badge.clock"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)
                }

                if let note = transfer.requestNote, !note.isEmpty {
                    Label(note, systemImage: "text.bubble")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
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
        let canOperateCustomerOrigin = transfer.transferType == "CUSTOMER_REQUEST"
            && branchID == transfer.originBranchID
        let canApprove = canOperate || canOperateCustomerOrigin

        if canOperate || isOwnTransfer {
            Divider()
            HStack(spacing: AppSpacing.small) {
                if ["RECOMMENDED", "REQUESTED"].contains(transfer.status)
                    && canApprove {
                    operationButton(
                        "Aprobar",
                        systemImage: "checkmark"
                    ) {
                        await viewModel.approve(transfer)
                    }
                }

                if transfer.status == "APPROVED" && canApprove {
                    operationButton(
                        "Iniciar",
                        systemImage: "shippingbox"
                    ) {
                        await viewModel.prepare(transfer)
                    }
                }

                if ["APPROVED", "PREPARING"].contains(transfer.status)
                    && canApprove {
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

                if ["REQUESTED", "RECOMMENDED", "APPROVED", "PREPARING"]
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
        case "REQUESTED", "RECOMMENDED", "APPROVED", "PREPARING":
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

    private func displayDate(_ value: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd"
        let output = DateFormatter()
        output.locale = Locale(identifier: "es_AR")
        output.dateFormat = "d MMM yyyy"
        guard let date = input.date(from: value) else { return value }
        return output.string(from: date)
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

private struct CustomerProductRequestView: View {
    let options: [CustomerRequestOptionDTO]
    let destinationBranchID: Int?
    let isLoading: Bool
    let onSave: (CustomerRequestOptionDTO, Int, String?) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var selectedID: String?
    @State private var quantity = 1
    @State private var note = ""
    @State private var isSaving = false

    private var filtered: [CustomerRequestOptionDTO] {
        let value = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return options }
        return options.filter {
            ($0.description ?? $0.sku).localizedCaseInsensitiveContains(value)
                || $0.sku.localizedCaseInsensitiveContains(value)
                || $0.originBranch.localizedCaseInsensitiveContains(value)
        }
    }

    private var selected: CustomerRequestOptionDTO? {
        options.first { $0.id == selectedID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Buscar stock") {
                    TextField("Producto, SKU o sucursal", text: $search)
                    Picker("Producto", selection: $selectedID) {
                        ForEach(filtered) { option in
                            Text(
                                "\(option.description ?? option.sku) · "
                                + "T. \(option.size) · \(option.originBranch)"
                            )
                            .tag(Optional(option.id))
                        }
                    }
                }

                if let selected {
                    Section("Pedido") {
                        LabeledContent("SKU", value: selected.sku)
                        LabeledContent("Talle", value: selected.size)
                        LabeledContent("Origen", value: selected.originBranch)
                        LabeledContent(
                            "Stock según última carga",
                            value: "\(selected.availableQuantity)"
                        )
                        Stepper(
                            "Cantidad: \(quantity)",
                            value: $quantity,
                            in: 1...max(selected.availableQuantity, 1)
                        )
                        TextField(
                            "Observación para la otra sucursal",
                            text: $note,
                            axis: .vertical
                        )
                        .lineLimit(2...4)
                    }

                    Section {
                        Label(
                            "La sucursal de origen debe confirmar que el producto "
                            + "existe físicamente antes de prepararlo.",
                            systemImage: "exclamationmark.shield"
                        )
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Pedir producto")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isLoading && options.isEmpty {
                    ProgressView("Consultando stock…")
                } else if !isLoading && options.isEmpty {
                    ContentUnavailableView(
                        "Sin stock disponible",
                        systemImage: "shippingbox",
                        description: Text(
                            "Generá una reposición con stock actualizado antes de usar este pedido."
                        )
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Solicitar") {
                        guard let selected else { return }
                        isSaving = true
                        Task {
                            if await onSave(
                                selected,
                                quantity,
                                note.isEmpty ? nil : note
                            ) {
                                dismiss()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(selected == nil || isSaving)
                }
            }
            .onAppear {
                selectedID = options.first?.id
            }
            .onChange(of: options) { _, values in
                if !values.contains(where: { $0.id == selectedID }) {
                    selectedID = values.first?.id
                }
            }
            .onChange(of: selectedID) { _, _ in quantity = 1 }
        }
    }
}
