import SwiftUI

struct LatestReportCard: View {

    let item: ReportModel

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            Text("Último reporte generado")
                .font(
                    .system(
                        size: 18,
                        weight: .semibold
                    )
                )

            HStack(
                alignment: .top,
                spacing: 18
            ) {

                ZStack {

                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(0.10))
                        .frame(width: 64, height: 64)

                    Image(systemName: "doc.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                }

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text(item.fileName)
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )

                    Text(
                        "\(item.date) • \(item.type)"
                    )
                    .font(.system(size: 14))
                    .foregroundColor(
                        AppColors.secondaryText
                    )

                    HStack(spacing: 24) {

                        metricBlock(
                            value: item.rows,
                            title: "Filas"
                        )

                        metricBlock(
                            value: item.sheets,
                            title: "Hojas"
                        )

                        metricBlock(
                            value: item.size,
                            title: "Tamaño"
                        )
                    }
                }
            }

            HStack(spacing: 12) {

                actionButton(
                    title: "Vista previa",
                    icon: "eye"
                )

                actionButton(
                    title: "Compartir",
                    icon: "square.and.arrow.up"
                )

                Button {

                } label: {

                    HStack(spacing: 8) {

                        Image(systemName: "arrow.down")

                        Text("Descargar")
                    }
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(AppColors.primaryText)
                    .cornerRadius(16)
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }

    func metricBlock(
        value: String,
        title: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(value)
                .font(
                    .system(
                        size: 20,
                        weight: .bold
                    )
                )

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(
                    AppColors.secondaryText
                )
        }
    }

    func actionButton(
        title: String,
        icon: String
    ) -> some View {

        Button {

        } label: {

            HStack(spacing: 8) {

                Image(systemName: icon)

                Text(title)
            }
            .font(
                .system(
                    size: 15,
                    weight: .medium
                )
            )
            .foregroundColor(
                AppColors.primaryText
            )
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        AppColors.border,
                        lineWidth: 1
                    )
            )
        }
    }
}