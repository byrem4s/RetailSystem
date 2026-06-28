import SwiftUI

struct AnalysisDateSelectorSheet: View {

    @Binding var selectedDate: Date

    let analyses: [AnalysisHistoryItemDTO]
    let isLoading: Bool
    let isHistoricalMode: Bool
    let historicalLabel: String?

    let onSearch: () -> Void
    let onSelect: (AnalysisHistoryItemDTO) -> Void
    let onClear: () -> Void

    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {

        NavigationView {

            ScrollView(showsIndicators: false) {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    DatePicker(
                        "Fecha",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(24)

                    Button {

                        onSearch()

                    } label: {

                        HStack {

                            if isLoading {

                                ProgressView()
                                    .tint(.white)

                            } else {

                                Image(systemName: "magnifyingglass")
                            }

                            Text(
                                isLoading
                                ? "Buscando..."
                                : "Buscar análisis"
                            )
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.blue)
                        .cornerRadius(16)
                    }
                    .disabled(isLoading)

                    if isHistoricalMode {

                        historicalModeCard
                    }

                    analysesSection
                }
                .padding(18)
            }
            .background(AppColors.background)
            .navigationTitle("Elegir análisis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var historicalModeCard: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Modo histórico activo")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            Text(historicalLabel ?? "Análisis histórico seleccionado")
                .font(.system(size: 13))
                .foregroundColor(AppColors.secondaryText)

            Button {

                onClear()
                dismiss()

            } label: {

                Text("Volver al último análisis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.blue.opacity(0.10))
                    .cornerRadius(14)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(22)
    }

    private var analysesSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Análisis encontrados")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            if analyses.isEmpty {

                EmptyStateView(
                    icon: "calendar",
                    title: "Sin selección",
                    message: "Elegí una fecha y tocá Buscar análisis."
                )

            } else {

                VStack(spacing: 12) {

                    ForEach(analyses) { item in

                        analysisRow(
                            item
                        )
                    }
                }
            }
        }
    }

    private func analysisRow(
        _ item: AnalysisHistoryItemDTO
    ) -> some View {

        Button {

            onSelect(item)
            dismiss()

        } label: {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                HStack {

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text("Análisis #\(item.executionID)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.primaryText)

                        Text("\(formatDate(item.date)) · \(item.time)")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.secondaryText)
                    }

                    Spacer()

                    statusBadge(
                        item.status
                    )
                }

                HStack(spacing: 10) {

                    miniMetric(
                        title: "Unidades",
                        value: "\(item.movements)"
                    )

                    miniMetric(
                        title: "Casos",
                        value: "\(item.detectedCases)"
                    )

                    miniMetric(
                        title: "Críticas",
                        value: "\(item.critical)"
                    )
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(22)
        }
        .buttonStyle(.plain)
    }

    private func miniMetric(
        title: String,
        value: String
    ) -> some View {

        VStack(spacing: 4) {

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(14)
    }

    private func statusBadge(
        _ status: String
    ) -> some View {

        let color = statusColor(
            status
        )

        return Text(status)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .cornerRadius(12)
    }

    private func statusColor(
        _ status: String
    ) -> Color {

        let value = status.uppercased()

        if value == "FAILED" {
            return AppColors.red
        }

        if value == "COMPLETED" {
            return AppColors.green
        }

        if value == "PROCESSING" || value == "GENERATED" {
            return AppColors.orange
        }

        return AppColors.blue
    }

    private func formatDate(
        _ value: String
    ) -> String {

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(
            from: value
        ) else {
            return value
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy"

        return outputFormatter.string(
            from: date
        )
    }
}