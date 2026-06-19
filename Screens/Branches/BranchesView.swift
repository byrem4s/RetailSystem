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

                if branchModels.isEmpty {

                    EmptyStateView(
                        icon: "building.2",
                        title: "Sin sucursales",
                        message: "No hay información disponible."
                    )

                } else {

                    VStack(spacing: 8) {

                        ForEach(
                            Array(branchModels.enumerated()),
                            id: \.element.id
                        ) { index, item in

                            BranchRankingRow(
                                position: index + 1,
                                item: item,
                                selected: index == 2
                            )
                        }
                    }
                }

                // MARK: DETAIL PANEL

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    Text("Detalle de sucursal")
                        .font(
                            .system(
                                size: 20,
                                weight: .bold
                            )
                        )

                    EmptyStateView(
                        icon: "building.2",
                        title: "Información avanzada no disponible",
                        message: "La V1 muestra salud, ranking y métricas generales. El detalle operativo llegará en una versión posterior."
                    )
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
    }
}

struct BranchesView_Previews: PreviewProvider {

    static var previews: some View {

        BranchesView()
    }
}