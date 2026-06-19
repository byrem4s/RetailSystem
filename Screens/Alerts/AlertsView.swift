import SwiftUI

struct AlertsView: View {

    @StateObject private var vm = AlertsViewModel()
    @State private var selectedFilter = "Todas"


    let filters = [
        "Todas",
        "Críticas",
        "Medias",
        "Info"
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

                    Text("Alerts")
                        .font(
                            .system(
                                size: 34,
                                weight: .bold
                            )
                        )

                    Text(
                        "Riesgos y oportunidades detectadas"
                    )
                    .font(.system(size: 14))
                    .foregroundColor(
                        AppColors.secondaryText
                    )
                }

                // MARK: SUMMARY CARDS

                HStack(spacing: 12) {

                    summaryCard(
                        title: "Críticas",
                        value: "\(vm.criticalCount)",
                        color: AppColors.red,
                        icon: "exclamationmark.triangle.fill"
                    )

                    summaryCard(
                        title: "Medias",
                        value: "\(vm.mediumCount)",
                        color: AppColors.orange,
                        icon: "clock.fill"
                    )

                    summaryCard(
                        title: "Info",
                        value: "0",
                        color: AppColors.blue,
                        icon: "info.circle.fill"
                    )

                    summaryCard(
                        title: "Total",
                        value: "\(vm.totalCount)",
                        color: AppColors.green,
                        icon: "chart.bar.fill"
                    )
                }

                // MARK: FILTERS

                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {

                    HStack(spacing: 10) {

                        ForEach(filters, id: \.self) { filter in

                            Button {

                                selectedFilter = filter

                            } label: {

                                Text(filter)
                                    .font(
                                        .system(
                                            size: 13,
                                            weight: .medium
                                        )
                                    )
                                    .foregroundColor(
                                        selectedFilter == filter
                                        ? .white
                                        : AppColors.primaryText
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedFilter == filter
                                        ? AppColors.blue
                                        : Color.white
                                    )
                                    .cornerRadius(14)
                            }
                        }
                    }
                }

                // MARK: CRITICAL

                sectionTitle(
                    title: "Alertas críticas",
                    color: AppColors.red
                )

                VStack(spacing: 14) {

                    VStack(spacing: 14) {

                        if vm.criticalAlerts.isEmpty {

                            EmptyStateView(
                                icon: "checkmark.circle",
                                title: "Sin alertas críticas",
                                message: "No hay problemas críticos detectados."
                            )

                        } else {

                            ForEach(vm.criticalAlerts) { item in
                                // tu card actual
                            }
                        }
                    }
                }

                // MARK: MEDIUM

                sectionTitle(
                    title: "Alertas medias",
                    color: AppColors.orange
                )

                VStack(spacing: 14) {

                    VStack(spacing: 14) {

                        if vm.criticalAlerts.isEmpty {

                            EmptyStateView(
                                icon: "checkmark.circle",
                                title: "Sin alertas críticas",
                                message: "No hay problemas críticos detectados."
                            )

                        } else {

                            ForEach(vm.criticalAlerts) { item in
                                // tu card actual
                            }
                        }
                    }
                }
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

            await vm.loadAlerts()
        }

        .onReceive(AppState.shared.$refreshID) { _ in

            Task {

                await vm.loadAlerts()
            }
        }
    }

    // MARK: SUMMARY CARD

    func summaryCard(
        title: String,
        value: String,
        color: Color,
        icon: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Image(systemName: icon)
                .foregroundColor(color)

            Text(value)
                .font(
                    .system(
                        size: 22,
                        weight: .bold
                    )
                )

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(
                    AppColors.secondaryText
                )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
    }

    // MARK: SECTION TITLE

    func sectionTitle(
        title: String,
        color: Color
    ) -> some View {

        HStack {

            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(
                    .system(
                        size: 18,
                        weight: .semibold
                    )
                )
        }
    }
}

struct AlertsView_Previews: PreviewProvider {

    static var previews: some View {

        AlertsView()
    }
}