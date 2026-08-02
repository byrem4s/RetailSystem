import SwiftUI

struct F8EditorView: View {
    @StateObject private var viewModel: F8EditorViewModel
    @State private var rowToDelete: F8RecommendationRowDTO?
    @State private var showsManualRow = false
    @Environment(\.dismiss) private var dismiss

    init(batchID: Int) {
        _viewModel = StateObject(
            wrappedValue: F8EditorViewModel(batchID: batchID)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ResponsiveScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        PageHeading(
                            eyebrow: "Borrador validado",
                            title: "Editar F8",
                            subtitle: (
                                "Ajustá cantidades o eliminá movimientos antes de "
                                + "distribuir. El sistema impide superar la necesidad "
                                + "y el stock transferible del origen."
                            )
                        )

                        if let notice = viewModel.noticeMessage {
                            Label(notice, systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.green)
                        }

                        if viewModel.rows.isEmpty && !viewModel.isBusy {
                            AppCard {
                                ContentUnavailableView(
                                    "F8 sin movimientos",
                                    systemImage: "doc.badge.minus",
                                    description: Text(
                                        "No quedan transferencias en este borrador."
                                    )
                                )
                            }
                        } else {
                            LazyVStack(spacing: AppSpacing.medium) {
                                ForEach(viewModel.rows) { row in
                                    recommendationCard(row)
                                }
                            }
                        }
                    }
                }

                if viewModel.isBusy {
                    Color.black.opacity(0.12).ignoresSafeArea()
                    ProgressView("Validando cambio…")
                        .padding(AppSpacing.large)
                        .background(.regularMaterial)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: AppSpacing.cardRadius,
                                style: .continuous
                            )
                        )
                }
            }
            .navigationTitle("Borrador F8")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showsManualRow = true
                    } label: {
                        Label("Agregar", systemImage: "plus")
                    }
                    .disabled(!viewModel.editable || viewModel.manualOptions == nil)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .sheet(isPresented: $showsManualRow) {
                if let options = viewModel.manualOptions {
                    AddManualF8RowView(
                        options: options,
                        onSave: { variant, destination, quantity in
                            await viewModel.addManualRow(
                                variant: variant,
                                destination: destination,
                                quantity: quantity
                            )
                        }
                    )
                }
            }
            .task { await viewModel.load() }
            .confirmationDialog(
                "¿Eliminar este movimiento?",
                isPresented: Binding(
                    get: { rowToDelete != nil },
                    set: { if !$0 { rowToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Eliminar del F8", role: .destructive) {
                    guard let row = rowToDelete else { return }
                    rowToDelete = nil
                    Task { await viewModel.remove(row) }
                }
                Button("Cancelar", role: .cancel) { rowToDelete = nil }
            } message: {
                Text("La necesidad volverá a figurar como parcial o sin resolver.")
            }
            .alert(
                "No se pudo guardar",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func recommendationCard(_ row: F8RecommendationRowDTO) -> some View {
        let quantity = Binding<Int>(
            get: { viewModel.quantities[row.id] ?? row.quantity },
            set: {
                viewModel.quantities[row.id] = $0
                viewModel.quantityChanged(for: row.id)
            }
        )
        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.regular) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.sku)
                            .font(AppTypography.cardTitle)
                        Text("Talle \(row.size) · necesidad \(row.neededQuantity)")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                        if row.sourceType == "MANUAL" {
                            StatusPill(
                                title: "DECISIÓN MANUAL",
                                color: AppColors.purple
                            )
                        }
                    }
                    Spacer()
                    StatusPill(
                        title: fulfillmentLabel(row.fulfillmentStatus),
                        color: fulfillmentColor(row.fulfillmentStatus)
                    )
                }

                HStack(spacing: AppSpacing.small) {
                    Label(row.origin, systemImage: "shippingbox")
                    Image(systemName: "arrow.right")
                        .foregroundStyle(AppColors.tertiaryText)
                    Label(row.destination, systemImage: "storefront")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

                Divider()

                Stepper(
                    value: quantity,
                    in: 1...max(row.maxQuantity, 1)
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cantidad: \(quantity.wrappedValue)")
                            .font(.subheadline.weight(.semibold))
                        Text("Máximo validado: \(row.maxQuantity)")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
                .disabled(!viewModel.editable)

                HStack(spacing: AppSpacing.medium) {
                    Button(role: .destructive) {
                        rowToDelete = row
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                    .disabled(!viewModel.editable)

                    Button {
                        Task { await viewModel.save(row) }
                    } label: {
                        Label(
                            viewModel.savedRowIDs.contains(row.id)
                                ? "Guardado"
                                : "Guardar",
                            systemImage: viewModel.savedRowIDs.contains(row.id)
                                ? "checkmark.circle.fill"
                                : "square.and.arrow.down"
                        )
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(
                        !viewModel.editable
                            || quantity.wrappedValue == row.quantity
                    )
                }
            }
        }
    }

    private func fulfillmentLabel(_ status: String) -> String {
        switch status {
        case "COMPLETE": return "COMPLETO"
        case "PARTIAL": return "PARCIAL"
        default: return "SIN CUBRIR"
        }
    }

    private func fulfillmentColor(_ status: String) -> Color {
        switch status {
        case "COMPLETE": return AppColors.green
        case "PARTIAL": return AppColors.orange
        default: return AppColors.red
        }
    }
}

private struct AddManualF8RowView: View {
    let options: F8ManualOptionsDTO
    let onSave: (
        F8ManualVariantDTO,
        F8ManualBranchDTO,
        Int
    ) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var selectedVariantID: String?
    @State private var selectedDestinationCode: String?
    @State private var quantity = 1
    @State private var isSaving = false

    private var variant: F8ManualVariantDTO? {
        options.variants.first { $0.id == selectedVariantID }
    }

    private var destinations: [F8ManualBranchDTO] {
        guard let variant else { return options.destinations }
        return options.destinations.filter { $0.code != variant.origin }
    }

    private var destination: F8ManualBranchDTO? {
        destinations.first { $0.code == selectedDestinationCode }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Producto disponible") {
                    Picker("Producto y origen", selection: $selectedVariantID) {
                        ForEach(options.variants) { item in
                            Text(
                                "\(item.description ?? item.sku) · "
                                + "T. \(item.size) · \(item.originName)"
                            )
                            .tag(Optional(item.id))
                        }
                    }
                    if let variant {
                        LabeledContent("SKU", value: variant.sku)
                        LabeledContent("Talle", value: variant.size)
                        LabeledContent("Origen", value: variant.originName)
                        LabeledContent(
                            "Disponible validado",
                            value: "\(variant.availableQuantity)"
                        )
                    }
                }

                Section("Destino y cantidad") {
                    Picker("Destino", selection: $selectedDestinationCode) {
                        ForEach(destinations) { branch in
                            Text(branch.name + (branch.isOutlet ? " · Outlet" : ""))
                                .tag(Optional(branch.code))
                        }
                    }
                    Stepper(
                        "Cantidad: \(quantity)",
                        value: $quantity,
                        in: 1...max(variant?.availableQuantity ?? 1, 1)
                    )
                }

                Section {
                    Label(
                        "Al guardar se vuelve a comprobar el stock, las reservas, "
                        + "las transferencias activas y todas las filas del F8.",
                        systemImage: "checkmark.shield"
                    )
                    .font(.caption)
                }
            }
            .navigationTitle("Agregar movimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Agregar") {
                        guard let variant, let destination else { return }
                        isSaving = true
                        Task {
                            if await onSave(variant, destination, quantity) {
                                dismiss()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(variant == nil || destination == nil || isSaving)
                }
            }
            .onAppear {
                selectedVariantID = options.variants.first?.id
                selectedDestinationCode = destinations.first?.code
            }
            .onChange(of: selectedVariantID) { _, _ in
                quantity = 1
                if !destinations.contains(
                    where: { $0.code == selectedDestinationCode }
                ) {
                    selectedDestinationCode = destinations.first?.code
                }
            }
        }
    }
}
