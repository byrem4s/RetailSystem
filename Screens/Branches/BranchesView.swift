import SwiftUI

struct BranchesView: View {

    @StateObject private var vm = BranchesViewModel()
    @State private var selectedFilter = "Ranking"

    let filters = [
        "Ranking",
        "Quiebre",
        "Sobrestock",
        "Sin rotación"
    ]

    var branchModels: [BranchModel] {

        vm.branches.map {

            BranchModel(
                dto: $0
            )
        }
    }

    var averageHealth: Int {

        guard !vm.branches.isEmpty else {

            return 0
        }

        let total = vm.branches.reduce(
            0
        ) {

            $0 + $1.health
        }

        return total /
        vm.branches.count
    }

    var totalCritical: Int {

        vm.branches.reduce(
            0
        ) {

            $0 + $1.critical
        }
    }

    var totalCases: Int {

        vm.branches.reduce(
            0
        ) {

                $0 + $1.totalCases
            }
        }


    let riskProducts: [BranchRiskProduct] = [

        .init(
            name: "Nike Revolution 7 - T42",
            status: "Riesgo de quiebre",
            stock: "1 u.",
            needed: "7 u.",
            color: AppColors.red
        ),

        .init(
            name: "Adidas RunFalcon - T40",
            status: "Reposición parcial",
            stock: "2 u.",
            needed: "5 u.",
            color: AppColors.orange
        ),

        .init(
            name: "Puma Smash - T43",
            status: "Riesgo de quiebre",
            stock: "0 u.",
            needed: "4 u.",
            color: AppColors.red
        )
    ]

    var body: some View {

        ScrollView(showsIndicators: false) {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                // MARK: HEADER

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

                    Text(
                        "Salud y desempeño de cada sucursal"
                    )
                    .font(.system(size: 14))
                    .foregroundColor(
                        AppColors.secondaryText
                    )
                }

                // MARK: TOP KPIS

                VStack(spacing: 14) {

                    HStack(spacing: 14) {

                        BranchHealthCard(
                            icon: "building.2.fill",
                            color: AppColors.green,
                            value: "\(vm.branches.count)",
                            title: "Sucursales",
                            subtitle: "activas"
                        )

                        BranchHealthCard(
                            icon: "waveform.path.ecg",
                            color: AppColors.orange,
                            value: "\(averageHealth)%",
                            title: "Salud promedio",
                            subtitle: "general"
                        )
                    }

                    HStack(spacing: 14) {

                        BranchHealthCard(
                            icon: "exclamationmark.triangle.fill",
                            color: AppColors.red,
                            value: "\(totalCritical)",
                            title: "Con riesgo",
                            subtitle: "alto"
                        )

                        BranchHealthCard(
                            icon: "arrow.left.arrow.right",
                            color: AppColors.blue,
                            value: "\(totalCases)",
                            title: "Movimientos",
                            subtitle: "hoy"
                        )
                    }
                }

                // MARK: FILTERS

                HStack(spacing: 0) {

                    ForEach(filters, id: \.self) { filter in

                        Button {

                            selectedFilter = filter

                        } label: {

                            Text(filter)
                                .font(
                                    .system(
                                        size: 13,
                                        weight: .semibold
                                    )
                                )
                                .foregroundColor(
                                    selectedFilter == filter
                                    ? AppColors.blue
                                    : AppColors.secondaryText
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(

                                    Group {

                                        if selectedFilter == filter {

                                            RoundedRectangle(
                                                cornerRadius: 16
                                            )
                                            .fill(Color.white)
                                            .padding(4)
                                        }
                                    }
                                )
                        }
                    }
                }
                .background(
                    Color.gray.opacity(0.08)
                )
                .cornerRadius(20)

                // MARK: RANKING

                VStack(spacing: 8) {

                    ForEach(Array(branchModels.enumerated()), id: \.element.id) { index, item in

                        BranchRankingRow(
                            position: index + 1,
                            item: item,
                            selected: index == 2
                        )
                    }
                }

                // MARK: DETAIL PANEL

                VStack(
                    alignment: .leading,
                    spacing: 22
                ) {

                    // HEADER

                    HStack {

                        VStack(
                            alignment: .leading,
                            spacing: 6
                        ) {

                            Text("Sucursal Norte")
                                .font(
                                    .system(
                                        size: 24,
                                        weight: .bold
                                    )
                                )

                            HStack(spacing: 8) {

                                Text("Salud: 72%")
                                    .font(
                                        .system(
                                            size: 13,
                                            weight: .semibold
                                        )
                                    )
                                    .foregroundColor(
                                        AppColors.orange
                                    )

                                Text("Riesgo medio")
                                    .font(.system(size: 13))
                                    .foregroundColor(
                                        AppColors.secondaryText
                                    )
                            }
                        }

                        Spacer()

                        Button {

                        } label: {

                            Text("Ver detalle")
                                .font(
                                    .system(
                                        size: 13,
                                        weight: .medium
                                    )
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .overlay(
                                    RoundedRectangle(
                                        cornerRadius: 14
                                    )
                                    .stroke(
                                        AppColors.blue
                                    )
                                )
                        }
                    }

                    // RESUMEN + EVOLUCION

                    HStack(alignment: .top, spacing: 16) {

                        VStack(
                            alignment: .leading,
                            spacing: 14
                        ) {

                            Text("Resumen de problemas")
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .semibold
                                    )
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            issueRow(
                                icon: "exclamationmark.triangle.fill",
                                title: "Riesgo de quiebre",
                                value: "11",
                                color: AppColors.red
                            )

                            issueRow(
                                icon: "clock.fill",
                                title: "Sin rotación",
                                value: "\(totalCritical)",
                                color: AppColors.orange
                            )

                            issueRow(
                                icon: "shippingbox.fill",
                                title: "Sobrestock",
                                value: "15",
                                color: AppColors.blue
                            )

                            issueRow(
                                icon: "chart.bar.fill",
                                title: "Curva incompleta",
                                value: "7",
                                color: AppColors.green
                            )
                        }

                        VStack(
                            alignment: .center,
                            spacing: 14
                        ) {

                            Text("Evolución de salud")
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .semibold
                                    )
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Spacer(minLength: 10)

                            VStack(spacing: 4) {

                                Text("72%")
                                    .font(
                                        .system(
                                            size: 42,
                                            weight: .bold
                                        )
                                    )
                                    .foregroundColor(
                                        AppColors.orange
                                    )

                                Text("Estado operacional")
                                    .font(.system(size: 12))
                                    .foregroundColor(
                                        AppColors.secondaryText
                                    )
                                    .multilineTextAlignment(.center)
                            }
                            Spacer(minLength: 10)
                        }
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    // PRODUCTS

                    VStack(
                        alignment: .leading,
                        spacing: 14
                    ) {

                        HStack {

                            Text(
                                "Productos con riesgo"
                            )
                            .font(
                                .system(
                                    size: 18,
                                    weight: .semibold
                                )
                            )

                            Spacer()

                            Button {

                            } label: {

                                Text("Ver todos")
                                    .font(
                                        .system(
                                            size: 13,
                                            weight: .medium
                                        )
                                    )
                                    .foregroundColor(
                                        AppColors.blue
                                    )
                            }
                        }

                        VStack(spacing: 6) {

                            ForEach(riskProducts) { item in
                                RiskProductRow(item: item)
                            }
                        }
                    }
                }
                .padding(22)
                .background(Color.white)
                .cornerRadius(28)
            }
            .padding(18)
            .padding(.bottom, 120)
        }
        .background(AppColors.background)

        .alert(

            "Error",

            isPresented: Binding(

                get: {

                    vm.errorMessage != nil
                },

                set: { _ in

                    vm.errorMessage = nil
                }
            )

        ) {

            Button("OK") {}

        } message: {

            Text(
                vm.errorMessage ?? ""
            )
        }

        .task {

            await vm.loadData()
        }

        .onReceive(AppState.shared.$refreshID) { _ in

            Task {

                await vm.loadData()
            }
        }

        .task {

            await vm.loadData()
        }
        .onReceive(
            AppState.shared.$refreshID
        ) { _ in

            Task {

                await vm.loadData()
            }
        }
    }

    // MARK: ISSUE ROW

    func issueRow(
        icon: String,
        title: String,
        value: String,
        color: Color
    ) -> some View {

        HStack {

            Image(systemName: icon)
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 14))

            Spacer()

            Text(value)
                .font(
                    .system(
                        size: 18,
                        weight: .bold
                    )
                )
                .foregroundColor(color)
        }
    }
}

struct BranchesView_Previews: PreviewProvider {

    static var previews: some View {

        BranchesView()
    }
}