import SwiftUI

struct ActivityView: View {
    @StateObject private var vm = ActivityViewModel()
    @State private var selectedFilter = "Todas"

    let filters = [
        "Todas",
        "Movimientos",
        "Decisiones",
        "Resueltas"
    ]


    var body: some View {

        ScrollView(showsIndicators: false) {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Activity")
                        .font(
                            .system(
                                size: 34,
                                weight: .bold
                            )
                        )

                    Text(
                        "Seguimiento de movimientos y decisiones"
                    )
                    .font(.system(size: 14))
                    .foregroundColor(
                        AppColors.secondaryText
                    )
                }

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

                HStack(spacing: 12) {

                    ActivitySummaryCard(
                        icon: "arrow.left.arrow.right",
                        color: AppColors.green,
                        value: "\(vm.activities.count)",
                        title: "Movimientos",
                        trend: "Live"
                    )

                    ActivitySummaryCard(
                        icon: "checkmark.circle",
                        color: AppColors.blue,
                        value: "\(vm.activities.filter { $0.priority == "LOW" }.count)",
                        title: "Baja",
                        trend: "Live"
                    )

                    ActivitySummaryCard(
                        icon: "clock",
                        color: AppColors.orange,
                        value: "\(vm.activities.filter { $0.priority != "LOW" }.count)",
                        title: "Alta",
                        trend: "Live"
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    Text("Hoy, 20 de mayo")
                        .font(
                            .system(
                                size: 22,
                                weight: .bold
                            )
                        )

                    VStack(spacing: 16) {

                        ForEach(vm.activities) { item in

                            RoundedContainer {

                                VStack(
                                    alignment: .leading,
                                    spacing: 8
                                ) {

                                    Text(item.title)
                                        .font(.headline)

                                    Text(item.branch)
                                        .font(.subheadline)

                                    Text(item.reason)
                                        .font(.caption)

                                    HStack {

                                        Text(item.priority)

                                        Spacer()

                                        Text(
                                            "Suggested: \(item.suggested)"
                                        )
                                    }
                                    .font(.caption)
                                }
                                .padding()
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

            await vm.loadData()
        }

        .onReceive(AppState.shared.$refreshID) { _ in

            Task {

                await vm.loadData()
            }
        }
    }
}

struct ActivityView_Previews: PreviewProvider {

    static var previews: some View {

        ActivityView()
    }
}