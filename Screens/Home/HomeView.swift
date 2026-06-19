import SwiftUI

struct ReportsView: View {

    @StateObject private var uploadVM = UploadViewModel()
    @StateObject private var reportsVM = ReportsViewModel()

    @State private var showPicker = false

    var body: some View {

        ZStack {

            ScrollView(showsIndicators: false) {

                VStack(
                    alignment: .leading,
                    spacing: 22
                ) {

                    headerSection

                    latestReportSection

                    historySection

                    configurationSection
                }
                .padding(.top, 28)
                .padding(18)
                .padding(.bottom, 120)
            }

            if uploadVM.isUploading || reportsVM.isLoading {

                Color.black.opacity(0.25)
                    .ignoresSafeArea()

                VStack(spacing: 16) {

                    ProgressView()

                    Text(
                        uploadVM.isUploading
                        ? "Procesando archivo..."
                        : "Cargando reportes..."
                    )
                    .foregroundColor(.white)
                }
            }
        }
        .background(AppColors.background)
        .alert(
            "Error",
            isPresented: Binding(
                get: {
                    uploadVM.errorMessage != nil
                    || reportsVM.errorMessage != nil
                },
                set: { _ in
                    uploadVM.errorMessage = nil
                    reportsVM.errorMessage = nil
                }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(
                uploadVM.errorMessage
                ?? reportsVM.errorMessage
                ?? ""
            )
        }
        .task {
            await reportsVM.loadReports()
        }
        .onReceive(AppState.shared.$refreshID) { _ in
            Task {
                await reportsVM.loadReports()
            }
        }
        .sheet(isPresented: $showPicker) {

            DocumentPicker { url in

                Task {

                    await uploadVM.uploadFile(
                        url: url
                    )

                    AppState.shared.refreshSystem()
                }
            }
        }
    }

    private var headerSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Reportes")
                .font(
                    .system(
                        size: 34,
                        weight: .bold
                    )
                )

            Text("Archivos generados por el sistema")
                .font(.system(size: 14))
                .foregroundColor(
                    AppColors.secondaryText
                )

            if uploadVM.uploadSuccess {

                HStack(spacing: 8) {

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.green)

                    Text(
                        uploadVM.pipelineExecuted
                        ? "Archivo procesado correctamente"
                        : "Archivo subido correctamente"
                    )
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.green)
                }
            }
        }
    }

    private var latestReportSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            if let latest = reportsVM.reports.first {

                RoundedContainer {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text("Último reporte")
                            .font(.headline)

                        Text(latest.createdAt)
                            .font(.system(size: 13))
                            .foregroundColor(
                                AppColors.secondaryText
                            )

                        Text(latest.analysisReport)
                            .font(.caption)
                            .foregroundColor(
                                AppColors.secondaryText
                            )
                    }
                    .padding()
                }

            } else {

                EmptyStateView(
                    icon: "doc.text",
                    title: "Sin reportes generados",
                    message: "Cuando ejecutes el pipeline, los reportes aparecerán aquí."
                )
            }
        }
    }

    private var historySection: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            Text("Historial de reportes")
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )

            HStack(spacing: 12) {

                HStack(spacing: 10) {

                    Image(systemName: "magnifyingglass")
                        .foregroundColor(
                            AppColors.secondaryText
                        )

                    Text("Buscar reportes...")
                        .foregroundColor(
                            AppColors.secondaryText
                        )
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)

                Button {

                    showPicker = true

                } label: {

                    HStack(spacing: 8) {

                        Image(systemName: "arrow.up.doc.fill")

                        Text("Upload")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.blue)
                    .cornerRadius(12)
                }
            }

            if reportsVM.reports.isEmpty {

                EmptyStateView(
                    icon: "tray",
                    title: "Historial vacío",
                    message: "Aún no hay archivos exportados."
                )

            } else {

                VStack(spacing: 14) {

                    ForEach(reportsVM.reports) { item in

                        RoundedContainer {

                            VStack(
                                alignment: .leading,
                                spacing: 8
                            ) {

                                Text("Analysis Report")
                                    .font(.headline)

                                Text(item.createdAt)
                                    .font(.system(size: 13))
                                    .foregroundColor(
                                        AppColors.secondaryText
                                    )

                                Text(item.analysisReport)
                                    .font(.caption)

                                Text(item.transferReport)
                                    .font(.caption)
                                    .foregroundColor(
                                        AppColors.secondaryText
                                    )
                            }
                            .padding()
                        }
                    }
                }
            }
        }
    }

    private var configurationSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Configuración")
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )

            configurationRow(
                icon: "gearshape",
                title: "Programación",
                subtitle: "Todos los días a las 08:30"
            )

            configurationRow(
                icon: "bell",
                title: "Notificaciones",
                subtitle: "Recibir cuando el reporte esté listo"
            )
        }
    }

    func configurationRow(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {

        HStack(spacing: 16) {

            ZStack {

                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.blue.opacity(0.10))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .foregroundColor(AppColors.blue)
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                    .font(
                        .system(
                            size: 16,
                            weight: .medium
                        )
                    )

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(
                        AppColors.secondaryText
                    )
            }

            Spacer()

            Text("Activo")
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundColor(AppColors.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    AppColors.green.opacity(0.12)
                )
                .cornerRadius(12)

            Image(systemName: "chevron.right")
                .foregroundColor(
                    AppColors.secondaryText
                )
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
    }
}

struct ReportsView_Previews: PreviewProvider {

    static var previews: some View {
        ReportsView()
    }
}