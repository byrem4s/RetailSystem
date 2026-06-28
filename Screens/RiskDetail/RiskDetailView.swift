import SwiftUI

struct RiskDetailView: View {

    let detail: RiskDetailDTO
    let isAddingToF8: Bool
    let onAddToF8: () -> Void

    @SwiftUI.Environment(\.dismiss) private var dismiss
    private var current: RiskDetailCurrentDTO {
        detail.current
    }

    var body: some View {

        ScrollView(showsIndicators: false) {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                headerSection

                mainMetricsSection

                reasonSection

                if let recommendation = detail.recommendation,
                    !AppState.shared.isHistoricalMode {

                        recommendationSection(
                            recommendation
                        )
                }

                if AppState.shared.isHistoricalMode {

                    historicalInfoSection
                }

                if let comparison = detail.comparison {
                    comparisonSection(
                        comparison
                    )
                }

                historySection
            }
            .padding(18)
            .padding(.bottom, 24)
        }
        .background(AppColors.background)
    }

    private var headerSection: some View {

        HStack(alignment: .top) {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text("Detalle del riesgo")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.primaryText)

                Text(current.branch)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)

                priorityBadge(
                    current.priority
                )
            }

            Spacer()

            Button {

                dismiss()

            } label: {

                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
    }

    private var mainMetricsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(current.productCode)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.primaryText)

                Text("Talle \(current.size)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(priorityColor(current.priority))
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {

                metricCard(
                    title: "Vendido",
                    value: "\(current.sold) u.",
                    color: AppColors.blue
                )

                metricCard(
                    title: "Stock actual",
                    value: "\(current.stock) u.",
                    color: priorityColor(current.priority)
                )

                metricCard(
                    title: "Necesidad",
                    value: "\(current.needed) u.",
                    color: AppColors.orange
                )

                metricCard(
                    title: "Pendiente",
                    value: "\(current.residualNeed) u.",
                    color: AppColors.red
                )

                metricCard(
                    title: "Velocidad",
                    value: "\(String(format: "%.2f", current.averageVelocity)) u/día",
                    color: AppColors.green
                )

                metricCard(
                    title: "Cobertura",
                    value: coverageText,
                    color: AppColors.blue
                )
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }

    private var reasonSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Motivo")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            Text(current.reason ?? "Sin motivo disponible.")
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }

    private func recommendationSection(
        _ recommendation: RiskDetailRecommendationDTO
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                Text("Recomendación")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppColors.primaryText)

                Spacer()

                Text(recommendation.confidence)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.blue.opacity(0.10))
                    .cornerRadius(12)
            }

            Text(recommendation.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.primaryText)

            Text(recommendation.reason)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {

                recommendationRow(
                    title: "Origen sugerido",
                    value: recommendation.suggestedOrigin
                )

                recommendationRow(
                    title: "Destino sugerido",
                    value: recommendation.suggestedDestination
                )

                recommendationRow(
                    title: "Cantidad sugerida",
                    value: "\(recommendation.suggestedQuantity) u."
                )
            }

            Button {

                onAddToF8()

            } label: {

                HStack {

                    if isAddingToF8 {

                        ProgressView()
                            .tint(.white)

                    } else {

                        Image(systemName: "plus.circle.fill")
                    }

                    Text(
                        isAddingToF8
                        ? "Agregando..."
                        : "Agregar al F8"
                    )
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    recommendation.canAddToF8
                    ? AppColors.blue
                    : Color.gray.opacity(0.45)
                )
                .cornerRadius(16)
            }
            .disabled(
                !recommendation.canAddToF8 || isAddingToF8
            )
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }

    private func comparisonSection(
        _ comparison: RiskDetailComparisonDTO
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Comparación")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            HStack(spacing: 12) {

                comparisonCard(
                    title: "Tendencia",
                    value: comparison.trend,
                    color: trendColor(comparison.impact)
                )

                comparisonCard(
                    title: "Impacto",
                    value: comparison.impact,
                    color: trendColor(comparison.impact)
                )
            }

            if let previous = comparison.previousResidualNeed,
               let current = comparison.currentResidualNeed {

                Text("Pendiente anterior: \(previous) u. → actual: \(current) u.")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }

    private var historySection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Historial")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            if detail.history.isEmpty {

                Text("No hay historial suficiente para este producto.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)

            } else {

                VStack(spacing: 10) {

                    ForEach(detail.history) { item in

                        historyRow(
                            item
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }

    private func metricCard(
        title: String,
        value: String,
        color: Color
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.gray.opacity(0.055))
        .cornerRadius(16)
    }

    private func recommendationRow(
        title: String,
        value: String
    ) -> some View {

        HStack {

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(AppColors.secondaryText)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.primaryText)
        }
    }

    private func comparisonCard(
        title: String,
        value: String,
        color: Color
    ) -> some View {

        VStack(spacing: 6) {

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.gray.opacity(0.055))
        .cornerRadius(16)
    }

    private func historyRow(
        _ item: RiskDetailHistoryPointDTO
    ) -> some View {

        HStack(spacing: 12) {

            Circle()
                .fill(priorityColor(item.priority))
                .frame(width: 10, height: 10)

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text("Run \(item.executionID)")
                    .font(.system(size: 13, weight: .semibold))

                Text(item.createdAt)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {

                Text(item.priority)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(priorityColor(item.priority))

                Text("Pendiente: \(item.residualNeed) u.")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }

    private func priorityBadge(
        _ priority: String
    ) -> some View {

        Text(priority)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(priorityColor(priority))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(priorityColor(priority).opacity(0.12))
            .cornerRadius(12)
    }

    private var coverageText: String {

        guard let coverageDays = current.coverageDays else {
            return "-"
        }

        return "\(String(format: "%.1f", coverageDays)) días"
    }

    private func priorityColor(
        _ priority: String
    ) -> Color {

        let value = priority.uppercased()

        if value == "CRITICAL" {
            return AppColors.red
        }

        if value == "HIGH" {
            return AppColors.orange
        }

        return AppColors.blue
    }

    private func trendColor(
        _ impact: String
    ) -> Color {

        let value = impact.uppercased()

        if value == "POSITIVE" {
            return AppColors.green
        }

        if value == "NEGATIVE" {
            return AppColors.red
        }

        if value == "ATTENTION" {
            return AppColors.orange
        }

        return AppColors.blue
    }

    private var historicalInfoSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Modo histórico")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            Text("Este detalle pertenece a un análisis anterior. Las acciones sobre F8 están deshabilitadas para evitar modificar pedidos actuales con datos históricos.")
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }
}