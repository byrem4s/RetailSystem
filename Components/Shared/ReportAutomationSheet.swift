import SwiftUI

struct ReportAutomationSheet: View {

    @ObservedObject var vm: ReportAutomationViewModel

    @Environment(\.dismiss) private var dismiss

    private let weekdayOptions: [(Int, String)] = [
        (0, "Lunes"),
        (1, "Martes"),
        (2, "Miércoles"),
        (3, "Jueves"),
        (4, "Viernes"),
        (5, "Sábado"),
        (6, "Domingo")
    ]

    var body: some View {

        NavigationView {

            ZStack {

                ScrollView(showsIndicators: false) {

                    VStack(
                        alignment: .leading,
                        spacing: 22
                    ) {

                        statusSection

                        settingsSection

                        actionsSection

                        runsSection
                    }
                    .padding(18)
                    .padding(.bottom, 24)
                }

                if vm.isLoading {

                    Color.black.opacity(0.18)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.3)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Reportes automáticos")
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
            .task {
                await vm.loadData()
            }
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
        }
    }

    private var statusSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text("Estado")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                    Text(vm.scheduleLabel)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                }

                Spacer()

                Text(vm.enabled ? "ACTIVO" : "INACTIVO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(vm.enabled ? AppColors.green : AppColors.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        (vm.enabled ? AppColors.green : AppColors.red)
                            .opacity(0.12)
                    )
                    .cornerRadius(12)
            }

            Text("Próxima ejecución: \(vm.nextRunText)")
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }

    private var settingsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            Toggle(
                "Activar reportes automáticos",
                isOn: $vm.enabled
            )
            .font(.system(size: 16, weight: .semibold))

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                Text("Frecuencia")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.primaryText)

                Picker(
                    "Frecuencia",
                    selection: $vm.frequency
                ) {

                    Text("Diario")
                        .tag("DAILY")

                    Text("Semanal")
                        .tag("WEEKLY")
                }
                .pickerStyle(.segmented)
            }

            if vm.frequency == "WEEKLY" {

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Text("Día")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                    Picker(
                        "Día",
                        selection: $vm.weekday
                    ) {

                        ForEach(
                            weekdayOptions,
                            id: \.0
                        ) { option in

                            Text(option.1)
                                .tag(option.0)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(16)
                }
            }

            DatePicker(
                "Hora",
                selection: $vm.selectedTime,
                displayedComponents: .hourAndMinute
            )
            .font(.system(size: 14, weight: .semibold))
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }

    private var actionsSection: some View {

        VStack(spacing: 12) {

            Button {

                Task {
                    await vm.saveConfig()
                }

            } label: {

                Text("Guardar configuración")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.blue)
                    .cornerRadius(16)
            }

            Button {

                Task {
                    await vm.runNow()
                }

            } label: {

                HStack {

                    if vm.isRunningNow {

                        ProgressView()
                            .tint(AppColors.blue)

                    } else {

                        Image(systemName: "play.circle.fill")
                    }

                    Text(
                        vm.isRunningNow
                        ? "Generando..."
                        : "Generar ahora"
                    )
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.blue.opacity(0.10))
                .cornerRadius(16)
            }
            .disabled(vm.isRunningNow)
        }
    }

    private var runsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Últimas ejecuciones")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            if vm.runs.isEmpty {

                EmptyStateView(
                    icon: "clock",
                    title: "Sin ejecuciones",
                    message: "Todavía no hay reportes automáticos generados."
                )

            } else {

                VStack(spacing: 12) {

                    ForEach(vm.runs.prefix(8)) { run in

                        runRow(
                            run
                        )
                    }
                }
            }
        }
    }

    private func runRow(
        _ run: ReportAutomationRunDTO
    ) -> some View {

        HStack(spacing: 12) {

            Circle()
                .fill(run.status.uppercased() == "COMPLETED" ? AppColors.green : AppColors.red)
                .frame(width: 10, height: 10)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(run.status)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.primaryText)

                Text(run.message ?? "Sin mensaje")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            if let executionID = run.executionID {

                Text("Run \(executionID)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AppColors.blue.opacity(0.10))
                    .cornerRadius(10)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(18)
    }
}