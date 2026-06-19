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

                        Text(
                            "Archivos generados por el sistema"
                        )
                        .font(.system(size: 14))
                        .foregroundColor(
                            AppColors.secondaryText
                        )

                        if uploadVM.uploadSuccess {

                            HStack(spacing: 8) {

                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.green)

                                Text("Archivo subido correctamente")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.green)
                            }
                        }

                        if let error = uploadVM.errorMessage {

                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.red)
                        }
                    }

                    if let latest = reportsVM.reports.first {

                        RoundedContainer {

                            VStack(
                                alignment: .leading,
                                spacing: 8
                            ) {

                                Text("Último reporte")
                                    .font(.headline)

                                Text(latest.createdAt)

                                Text(latest.analysisReport)
                                    .font(.caption)
                                    .foregroundColor(
                                        AppColors.secondaryText
                                    )
                            }
                            .padding()
                        }
                    }

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

                                        Text(item.analysisReport)
                                            .font(.caption)

                                        Text(item.transferReport)
                                            .font(.caption)

                                    }
                                    .padding()
                                }
                            }
                        }
                    }

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
                .padding(18)
                .padding(.bottom, 120)
            }
            if uploadVM.isUploading {

                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {

                    ProgressView()

                    Text("Subiendo archivo...")
                        .foregroundColor(.white)
                }
            }
        }
        .background(AppColors.background)

        .task {

            await reportsVM.loadReports()
        }
        .onReceive(
            AppState.shared.$refreshID
        ) { _ in

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