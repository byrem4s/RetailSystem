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

                    uploadStatusSection

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

        HStack {

            VStack(
                alignment: .leading,
                spacing: 4
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
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()

            Button {

                showPicker = true

            } label: {

                ZStack {

                    Circle()
                        .fill(Color.white)
                        .frame(width: 46, height: 46)

                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                }
            }
        }
    }

    private var uploadStatusSection: some View {

        Group {

            if uploadVM.uploadSuccess {

                RoundedContainer {

                    HStack(spacing: 12) {

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.green)

                        Text(
                            uploadVM.pipelineExecuted
                            ? "Archivo procesado correctamente"
                            : "Archivo subido correctamente"
                        )
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.green)

                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }

    private var latestReportSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            if let latest = reportsVM.latest {

                LatestReportCard(
                    item: reportModel(from: latest)
                )

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
                        .foregroundColor(AppColors.secondaryText)

                    Text("Buscar reportes...")
                        .foregroundColor(AppColors.secondaryText)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)

                Button {

                } label: {

                    HStack(spacing: 8) {

                        Image(systemName: "line.3.horizontal.decrease.circle")

                        Text("Filtros")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color.white)
                    .cornerRadius(16)
                }
            }

            if reportsVM.history.isEmpty {

                EmptyStateView(
                    icon: "tray",
                    title: "Historial vacío",
                    message: "Aún no hay archivos exportados."
                )

            } else {

                VStack(spacing: 14) {

                    ForEach(reportsVM.history) { item in

                        ReportHistoryCard(
                            item: reportModel(from: item)
                        )
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

            Text("Configuración de reportes")
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )

            configurationRow(
                icon: "gearshape",
                title: "Programación",
                subtitle: reportsVM.scheduleText,
                isActive: true
            )

            configurationRow(
                icon: "bell",
                title: "Notificaciones",
                subtitle: "Recibir cuando el reporte esté listo",
                isActive: reportsVM.notificationsEnabled
            )
        }
    }

    private func configurationRow(
        icon: String,
        title: String,
        subtitle: String,
        isActive: Bool
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
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()

            Text(isActive ? "Activo" : "Inactivo")
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundColor(
                    isActive
                    ? AppColors.green
                    : AppColors.secondaryText
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isActive
                    ? AppColors.green.opacity(0.12)
                    : Color.gray.opacity(0.12)
                )
                .cornerRadius(12)

            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
    }

    private func reportModel(
        from dto: ReportDTO
    ) -> ReportModel {

        ReportModel(
            fileName: dto.fileName,
            date: dto.createdAt,
            type: dto.type,
            rows: dto.rows,
            sheets: dto.sheets,
            size: dto.size,
            status: statusText(dto.status),
            statusColor: statusColor(dto.status)
        )
    }

    private func statusText(
        _ status: String
    ) -> String {

        switch status.uppercased() {

        case "COMPLETED":
            return "Completado"

        case "PARTIAL":
            return "Parcial"

        case "ERROR":
            return "Error"

        default:
            return status
        }
    }

    private func statusColor(
        _ status: String
    ) -> Color {

        switch status.uppercased() {

        case "COMPLETED":
            return AppColors.green

        case "PARTIAL":
            return AppColors.orange

        case "ERROR":
            return AppColors.red

        default:
            return AppColors.secondaryText
        }
    }
}

struct ReportsView_Previews: PreviewProvider {

    static var previews: some View {
        ReportsView()
    }
}