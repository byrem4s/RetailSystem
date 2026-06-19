import SwiftUI


struct HomeView: View {

    @StateObject private var vm = HomeViewModel()

    var kpis: [KPIModel] {

        [

            .init(

                icon: "cpu.fill",

                color: AppColors.blue,

                value: vm.homeData?.pipeline ?? "-",

                title: "Pipeline",

                subtitle: "estado operacional"
            ),

            .init(

                icon: "shippingbox.fill",

                color: AppColors.green,

                value: vm.homeData?.stockDataset ?? "-",

                title: "Stock",

                subtitle: "dataset"
            ),

            .init(

                icon: "building.2.fill",

                color: AppColors.orange,

                value: vm.homeData?.depositoDataset ?? "-",

                title: "Deposito",

                subtitle: "estado"
            ),

            .init(

                icon: "clock.fill",

                color: AppColors.red,

                value: vm.homeData?.stockFreshness ?? "-",

                title: "Freshness",

                subtitle: "sincronización"
            )
        ]

        }

    // let alerts: [AlertModel] = [

    //     .init(
    //         icon: "exclamationmark.triangle.fill",
    //         color: AppColors.red,
    //         value: "10",
    //         title: "Riesgo crítico",
    //         subtitle: "Acción inmediata"
    //     ),

    //     .init(
    //         icon: "clock.fill",
    //         color: AppColors.orange,
    //         value: "8",
    //         title: "Riesgo medio",
    //         subtitle: "Revisar pronto"
    //     ),

    //     .init(
    //         icon: "info.circle.fill",
    //         color: AppColors.blue,
    //         value: "12",
    //         title: "Informativas",
    //         subtitle: "Para considerar"
    //     )
    // ]

    // let activities: [ActivityModel] = [

    //     .init(
    //         icon: "arrow.up.right",
    //         color: AppColors.green,
    //         title: "Transferencia completada",
    //         description: "12 unidades Air Max SC T42",
    //         detail: "Depósito Central → Alto Palermo",
    //         time: "09:32"
    //     ),

    //     .init(
    //         icon: "chart.pie.fill",
    //         color: AppColors.orange,
    //         title: "Reposición parcial",
    //         description: "Nike Revolution 7 T41",
    //         detail: "Sucursal 47",
    //         time: "08:47"
    //     )
    // ]

    var body: some View {

        ZStack {

            ScrollView(
                showsIndicators: false
            ) {

            VStack(
                alignment: .leading,
                spacing: 22
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    
                    Text(
                        vm.homeData?.pipeline ?? "-"
                        )

                    Text("Home")
                        .font(
                            .system(
                                size: 34,
                                weight: .bold
                            )
                        )

                    Text("Resumen operativo")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.secondaryText)
                }

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text("Hola, Equipo")
                        .font(
                            .system(
                                size: 20,
                                weight: .semibold
                            )
                        )

                    Text("Estado general del sistema")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                }

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    SectionHeader(
                        title: "Resumen general",
                        actionTitle: nil
                    )

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 14
                    ) {

                        ForEach(kpis) { item in
                            KPICard(item: item)
                        }
                    }
                }

                VStack(
                    alignment: .leading,
                    spacing: 14
                    ) {

                    SectionHeader(
                        title: "Alertas activas",
                        actionTitle: nil
                    )

                    VStack(spacing: 10) {

                        ForEach(vm.warnings) { item in

                            AlertOperationalCard(

                                item: OperationalAlertModel(

                                    title: item.message,

                                    subtitle: "Operational warning",

                                    branch: "System",

                                    sold: "0",

                                    stock: "0",

                                    velocity: "0",

                                    needed: "0",

                                    risk: "WARNING",

                                    time: "NOW",

                                    color: .orange,

                                    icon: "exclamationmark.triangle.fill",

                                    description: item.message
                                )
                            )
                        }
                    }

                }

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    VStack(
                        alignment: .leading,
                        spacing: 14
                    ) {

                        SectionHeader(
                            title: "Estado operacional",
                            actionTitle: nil
                        )

                        VStack(spacing: 10) {

                            ForEach(vm.warnings) { item in

                                RoundedContainer {

                                    HStack(spacing: 12) {

                                        Image(
                                            systemName:
                                            "exclamationmark.triangle.fill"
                                        )
                                        .foregroundColor(.orange)

                                        Text(item.message)

                                        Spacer()
                                    }
                                    .padding()
                                }
                            }
                        }
                    }

                    VStack(spacing: 10) {

                        ForEach(vm.warnings) { item in

                            ActivityTimelineCard(

                                item: ActivityEventModel(

                                    title: item.message,

                                    description: "Operational warning",

                                    time: "now"
                                )
                            )
                        }
                    }
                }

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    SectionHeader(
                        title: "Últimos reportes",
                        actionTitle: nil
                    )

                    VStack(spacing: 10) {

                        ForEach(vm.exports.prefix(3)) { item in

                            LatestReportCard(

                                item: ReportModel(

                                    fileName: "Analysis Report",

                                    date: item.createdAt,

                                    type: "XLSX",

                                    rows: "-",

                                    sheets: "1",

                                    size: "-",

                                    status: "GENERATED",

                                    statusColor: .green
                                )
                            )
                        }
                    }
                }
            }
            .padding(18)
            .padding(.bottom, 100)

            }

            if vm.isLoading {

                Color.black.opacity(0.2)
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.4)
            }
        }
        .background(AppColors.background)
        .ignoresSafeArea()

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

struct HomeView_Previews: PreviewProvider {

    static var previews: some View {

        HomeView()
    }
}