import SwiftUI

struct BranchesView: View {

    @StateObject private var vm = BranchesViewModel()
    @State private var selectedFilter = "Ranking de salud"

    private let filters = [
        "Ranking de salud",
        "Riesgo de quiebre",
        "Sobrestock",
        "Sin rotación"
    ]

    private var filteredRanking: [BranchRankingDTO] {

        switch selectedFilter {

        case "Riesgo de quiebre":
            return vm.ranking.sorted {
                $0.critical > $1.critical
            }

        case "Sobrestock":
            return vm.ranking.sorted {
                $0.medium > $1.medium
            }

        case "Sin rotación":
            return vm.ranking.sorted {
                $0.high > $1.high
            }

        default:
            return vm.ranking.sorted {
                $0.health > $1.health
            }
        }
    }

    var body: some View {

        ZStack {

            ScrollView(showsIndicators: false) {

                VStack(
                    alignment: .leading,
                    spacing: 22
                ) {

                    headerSection

                    summarySection

                    filtersSection

                    rankingSection

                    selectedBranchSection
                }
                .padding(.top, 28)
                .padding(18)
                .padding(.bottom, 120)
            }

            if vm.isLoading {

                Color.black.opacity(0.20)
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.4)
            }
        }
        .background(AppColors.background)
        .alert(
            "Error",
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { _ in vm.errorMessage = nil }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .task {
            await vm.loadData()
        }
        .onReceive(AppState.shared.$refreshID) { _ in
            Task {
                await vm.loadData()
            }
        }
    }

    private var headerSection: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Sucursales")
                    .font(
                        .system(
                            size: 34,
                            weight: .bold
                        )
                    )

                Text("Salud y desempeño de cada sucursal")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()

            HStack(spacing: 10) {

                headerIcon("magnifyingglass")

                headerIcon("line.3.horizontal.decrease")
            }
        }
    }

    private func headerIcon(
        _ icon: String
    ) -> some View {

        Button {

        } label: {

            ZStack {

                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
            }
        }
    }

    private var summarySection: some View {

        HStack(spacing: 0) {

            summaryCard(
                icon: "building.2.fill",
                color: AppColors.green,
                value: "\(vm.branchesCount)",
                title: "Sucursales",
                subtitle: "activas"
            )

            verticalDivider

            summaryCard(
                icon: "waveform.path.ecg",
                color: healthColor(vm.averageHealth),
                value: "\(vm.averageHealth)%",
                title: "Salud promedio",
                subtitle: "general"
            )

            verticalDivider

            summaryCard(
                icon: "exclamationmark.triangle.fill",
                color: AppColors.red,
                value: "\(vm.highRisk)",
                title: "Con riesgo alto",
                subtitle: "casos"
            )

            verticalDivider

            summaryCard(
                icon: "arrow.left.arrow.right",
                color: AppColors.blue,
                value: "\(vm.movements)",
                title: "Movimientos",
                subtitle: "hoy"
            )
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
    }

    private var verticalDivider: some View {

        Rectangle()
            .fill(Color.gray.opacity(0.15))
            .frame(width: 1, height: 86)
    }

    private func summaryCard(
        icon: String,
        color: Color,
        value: String,
        title: String,
        subtitle: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            ZStack {

                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .foregroundColor(color)
            }

            Text(value)
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private var filtersSection: some View {

        HStack(spacing: 0) {

            ForEach(filters, id: \.self) { filter in

                Button {

                    selectedFilter = filter

                } label: {

                    Text(filter)
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(
                            selectedFilter == filter
                            ? AppColors.blue
                            : AppColors.primaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if selectedFilter == filter {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .padding(4)
                                }
                            }
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .background(Color.gray.opacity(0.08))
        .cornerRadius(20)
    }

    private var rankingSection: some View {

        VStack(spacing: 10) {

            if filteredRanking.isEmpty {

                EmptyStateView(
                    icon: "building.2",
                    title: "Sin sucursales",
                    message: "No hay información disponible."
                )

            } else {

                ForEach(
                    Array(filteredRanking.enumerated()),
                    id: \.element.id
                ) { index, branch in

                    rankingRow(
                        branch,
                        position: index + 1,
                        selected: branch.id == vm.selectedBranch?.id
                    )
                }
            }
        }
    }

    private func rankingRow(
        _ item: BranchRankingDTO,
        position: Int,
        selected: Bool
    ) -> some View {

        HStack(spacing: 14) {

            Text("\(position)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)
                .frame(width: 22)

            ZStack {

                Circle()
                    .stroke(
                        healthColor(item.health).opacity(0.25),
                        lineWidth: 5
                    )
                    .frame(width: 48, height: 48)

                Circle()
                    .trim(
                        from: 0,
                        to: CGFloat(item.health) / 100
                    )
                    .stroke(
                        healthColor(item.health),
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 48, height: 48)

                Text("\(item.health)%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(healthColor(item.health))
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(item.branch)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)

                Text(item.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()

            rankingMetric(
                title: "Críticas",
                value: item.critical,
                color: AppColors.red
            )

            rankingMetric(
                title: "Altas",
                value: item.high,
                color: AppColors.orange
            )

            rankingMetric(
                title: "Medias",
                value: item.medium,
                color: AppColors.blue
            )

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    selected
                    ? AppColors.blue.opacity(0.70)
                    : Color.gray.opacity(0.08),
                    lineWidth: selected ? 1.4 : 1
                )
        )
    }

    private func rankingMetric(
        title: String,
        value: Int,
        color: Color
    ) -> some View {

        VStack(spacing: 4) {

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(AppColors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("\(value)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: 42)
    }

    private var selectedBranchSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            if let branch = vm.selectedBranch {

                selectedBranchCard(branch)

            } else {

                EmptyStateView(
                    icon: "building.2",
                    title: "Sin detalle disponible",
                    message: "No hay una sucursal seleccionada."
                )
            }
        }
    }

    private func selectedBranchCard(
        _ branch: SelectedBranchDTO
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            HStack {

                ZStack {

                    RoundedRectangle(cornerRadius: 16)
                        .fill(healthColor(branch.health).opacity(0.12))
                        .frame(width: 50, height: 50)

                    Image(systemName: "building.2.fill")
                        .foregroundColor(healthColor(branch.health))
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(branch.branch)
                        .font(.system(size: 22, weight: .bold))

                    HStack(spacing: 8) {

                        Text("Salud: \(branch.health)%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(healthColor(branch.health))

                        Text(branch.riskLevel)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }

                Spacer()

                Button {

                } label: {

                    Text("Ver detalle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.blue)
                        )
                }
            }

            HStack(
                alignment: .top,
                spacing: 18
            ) {

                problemsSummary(branch)

                healthEvolutionPlaceholder(branch)
            }

            riskProductsSection(branch)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(28)
    }

    private func problemsSummary(
        _ branch: SelectedBranchDTO
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Resumen de problemas")
                .font(.system(size: 15, weight: .semibold))

            problemRow(
                icon: "exclamationmark.triangle.fill",
                title: "Riesgo crítico",
                value: branch.critical,
                color: AppColors.red
            )

            problemRow(
                icon: "flame.fill",
                title: "Riesgo alto",
                value: branch.high,
                color: AppColors.orange
            )

            problemRow(
                icon: "clock.fill",
                title: "Riesgo medio",
                value: branch.medium,
                color: AppColors.blue
            )

            problemRow(
                icon: "list.bullet.rectangle",
                title: "Total casos",
                value: branch.totalCases,
                color: AppColors.green
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func problemRow(
        icon: String,
        title: String,
        value: Int,
        color: Color
    ) -> some View {

        HStack(spacing: 10) {

            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 18)

            Text(title)
                .font(.system(size: 13))

            Spacer()

            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
    }

    private func healthEvolutionPlaceholder(
        _ branch: SelectedBranchDTO
    ) -> some View {

        VStack(
            alignment: .center,
            spacing: 14
        ) {

            Text("Evolución de salud")
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Text("\(branch.health)%")
                .font(
                    .system(
                        size: 42,
                        weight: .bold
                    )
                )
                .foregroundColor(healthColor(branch.health))

            Text("Estado operacional")
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity)
    }

    private func riskProductsSection(
        _ branch: SelectedBranchDTO
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                Text("Productos con riesgo")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text("Ver todos (\(branch.riskProducts.count))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.blue)
            }

            if branch.riskProducts.isEmpty {

                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "Sin productos críticos",
                    message: "No hay productos con riesgo para esta sucursal."
                )

            } else {

                VStack(spacing: 4) {

                    ForEach(branch.riskProducts) { product in

                        riskProductRow(product)
                    }
                }
            }
        }
    }

    private func riskProductRow(
        _ product: BranchRiskProductDTO
    ) -> some View {

        HStack(spacing: 12) {

            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.10))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "shippingbox.fill")
                        .foregroundColor(productColor(product.priority))
                )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(2)

                Text(product.status)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(productColor(product.priority))
            }

            Spacer()

            VStack(spacing: 4) {

                Text("Stock")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)

                Text("\(product.stock) u.")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(productColor(product.priority))
            }

            VStack(spacing: 4) {

                Text("Necesidad")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)

                Text("\(product.needed) u.")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(productColor(product.priority))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(.vertical, 10)
    }

    private func healthColor(
        _ health: Int
    ) -> Color {

        if health >= 85 {
            return AppColors.green
        }

        if health >= 60 {
            return AppColors.orange
        }

        return AppColors.red
    }

    private func productColor(
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
}

struct BranchesView_Previews: PreviewProvider {

    static var previews: some View {
        BranchesView()
    }
}   