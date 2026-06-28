import SwiftUI

struct BranchesView: View {

    @StateObject private var vm = BranchesViewModel()

    @State private var selectedFilter = "Ranking"
    @State private var showAllBranches = false

    private let filters = [
        "Ranking",
        "Quiebre",
        "Sobrestock",
        "Sin rot."
    ]

    private var filteredRanking: [BranchRankingDTO] {

        switch selectedFilter {

        case "Quiebre":
            return vm.ranking.sorted {
                $0.issues.breakRisk > $1.issues.breakRisk
            }

        case "Sobrestock":
            return vm.ranking.sorted {
                $0.issues.overstock > $1.issues.overstock
            }

        case "Sin rot.":
            return vm.ranking.sorted {
                $0.issues.noRotation > $1.issues.noRotation
            }

        default:
            return vm.ranking.sorted {
                $0.health > $1.health
            }
        }
    }

    private var visibleRanking: [BranchRankingDTO] {

        showAllBranches
        ? filteredRanking
        : Array(filteredRanking.prefix(4))
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
                .padding(.bottom, 105)
            }

            if vm.isLoading {

                Color.black.opacity(0.20)
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.4)
            }

            if vm.isRiskDetailLoading {

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
        )
        .sheet(
            item: $vm.selectedRiskDetail
        ) { detail in

            RiskDetailView(
                detail: detail,
                isAddingToF8: vm.isAddingRiskToF8,
                onAddToF8: {
                    Task {
                        await vm.addRiskRecommendationToF8(
                            riskKey: detail.id
                        )
                    }
                }
            )
        } {
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
                title: "Salud",
                subtitle: "promedio"
            )

            verticalDivider

            summaryCard(
                icon: "exclamationmark.triangle.fill",
                color: AppColors.red,
                value: "\(vm.highRisk)",
                title: "Sucursales",
                subtitle: "con riesgo"
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
        .padding(14)
        .background(Color.white)
        .cornerRadius(24)
    }

    private var verticalDivider: some View {

        Rectangle()
            .fill(Color.gray.opacity(0.15))
            .frame(width: 1, height: 96)
    }

    private func summaryCard(
        icon: String,
        color: Color,
        value: String,
        title: String,
        subtitle: String
    ) -> some View {

        VStack(
            alignment: .center,
            spacing: 8
        ) {

            ZStack {

                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            .frame(height: 42)

            Text(value)
                .font(.system(size: 23, weight: .bold))
                .foregroundColor(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(height: 27)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .frame(height: 28, alignment: .top)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(height: 14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 122)
        .padding(.horizontal, 4)
    }

    private var filtersSection: some View {

        HStack(spacing: 0) {

            ForEach(filters, id: \.self) { filter in

                Button {

                    selectedFilter = filter
                    showAllBranches = false

                } label: {

                    Text(filter)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(
                            selectedFilter == filter
                            ? AppColors.blue
                            : AppColors.primaryText
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .background(
                            Group {
                                if selectedFilter == filter {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                }
                            }
                        )
                }
            }
        }
        .frame(height: 42)
        .padding(4)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(20)
    }

    private var rankingSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            if filteredRanking.isEmpty {

                EmptyStateView(
                    icon: "building.2",
                    title: "Sin sucursales",
                    message: "No hay información disponible."
                )

            } else {

                VStack(spacing: 10) {

                    ForEach(
                        Array(visibleRanking.enumerated()),
                        id: \.element.id
                    ) { index, branch in

                        rankingRow(
                            branch,
                            position: index + 1,
                            selected: branch.id == vm.selectedBranchID
                        )
                    }
                }

                if filteredRanking.count > 4 {

                    Button {

                        withAnimation(.easeInOut) {
                            showAllBranches.toggle()
                        }

                    } label: {

                        HStack(spacing: 6) {

                            Text(
                                showAllBranches
                                ? "Mostrar menos"
                                : "Ver todas las sucursales (22)"
                            )

                            Image(
                                systemName: showAllBranches
                                ? "chevron.up"
                                : "chevron.down"
                            )
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }

    private func rankingRow(
        _ item: BranchRankingDTO,
        position: Int,
        selected: Bool
    ) -> some View {

        Button {

            Task {
                await vm.selectBranch(
                    item.id
                )
            }

        } label: {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                HStack(spacing: 12) {

                    Text("\(position)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.secondaryText)
                        .frame(width: 22)

                    healthCircle(
                        value: item.health
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(item.branch)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        Text(item.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.secondaryText)
                }

                HStack(spacing: 10) {

                    rankingIssueMetric(
                        title: "Quiebre",
                        value: item.issues.breakRisk,
                        color: AppColors.red
                    )

                    rankingIssueMetric(
                        title: "Sin rotación",
                        value: item.issues.noRotation,
                        color: AppColors.orange
                    )

                    rankingIssueMetric(
                        title: "Sobrestock",
                        value: item.issues.overstock,
                        color: AppColors.blue
                    )
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        selected
                        ? AppColors.blue.opacity(0.85)
                        : Color.gray.opacity(0.08),
                        lineWidth: selected ? 1.6 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func healthCircle(
        value: Int
    ) -> some View {

        ZStack {

            Circle()
                .stroke(
                    healthColor(value).opacity(0.25),
                    lineWidth: 5
                )
                .frame(width: 48, height: 48)

            Circle()
                .trim(
                    from: 0,
                    to: CGFloat(value) / 100
                )
                .stroke(
                    healthColor(value),
                    style: StrokeStyle(
                        lineWidth: 5,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 48, height: 48)

            Text("\(value)%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(healthColor(value))
        }
    }

    private func rankingIssueMetric(
        title: String,
        value: Int,
        color: Color
    ) -> some View {

        HStack(spacing: 6) {

            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            Text("\(value)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.045))
        .cornerRadius(12)
    }

    private var selectedBranchSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            if vm.isDetailLoading {

                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white)
                    .frame(height: 180)
                    .overlay(
                        ProgressView()
                    )

            } else if let branch = vm.selectedBranchDetail {

                selectedBranchCard(
                    branch
                )

            } else {

                EmptyStateView(
                    icon: "building.2",
                    title: "Sin detalle disponible",
                    message: "Selecciona una sucursal para ver su información."
                )
            }
        }
    }

    private func selectedBranchCard(
        _ branch: BranchDetailDTO
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
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

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

                problemsSummary(
                    branch
                )

                healthEvolutionPlaceholder(
                    branch
                )
            }

            riskProductsSection(
                branch
            )
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(28)
    }

    private func problemsSummary(
        _ branch: BranchDetailDTO
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Resumen de problemas")
                .font(.system(size: 15, weight: .semibold))

            problemRow(
                icon: "exclamationmark.triangle.fill",
                title: "Riesgo de quiebre",
                value: branch.issues.breakRisk,
                color: AppColors.red
            )

            problemRow(
                icon: "clock.fill",
                title: "Sin rotación",
                value: branch.issues.noRotation,
                color: AppColors.orange
            )

            problemRow(
                icon: "shippingbox.fill",
                title: "Sobrestock",
                value: branch.issues.overstock,
                color: AppColors.blue
            )

            problemRow(
                icon: "chart.bar.fill",
                title: "Curva incompleta",
                value: branch.issues.incompleteCurve,
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
    }

    private func healthEvolutionPlaceholder(
        _ branch: BranchDetailDTO
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
        _ branch: BranchDetailDTO
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

                        riskProductRow(
                            product
                        )
                    }
                }
            }
        }
    }

    private func riskProductRow(
        _ product: BranchRiskProductDTO
    ) -> some View {

        Button {

            Task {
                await vm.openRiskDetail(
                    riskKey: product.id
                )
            }

        } label: {

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
        .buttonStyle(.plain)
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