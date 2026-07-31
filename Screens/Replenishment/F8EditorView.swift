import SwiftUI

struct F8EditorView: View {
    @StateObject private var viewModel: F8EditorViewModel
    @State private var rowToDelete: F8RecommendationRowDTO?
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
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
            set: { viewModel.quantities[row.id] = $0 }
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
                        Label("Guardar", systemImage: "checkmark")
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

