import SwiftUI

struct LatestReportCard: View {

    let item: ReportModel

    let onPreview: () -> Void
    let onShare: () -> Void
    let onDownload: () -> Void

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

                ExcelFileIcon(
                    size: 66
                )

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
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(
                        "\(item.date) • \(item.type)"
                    )
                    .font(.system(size: 14))
                    .foregroundColor(
                        AppColors.secondaryText
                    )

                    HStack(spacing: 28) {

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

            VStack(spacing: 10) {

                HStack(spacing: 10) {

                    reportActionButton(
                        title: "Vista previa",
                        icon: "eye",
                        primary: false,
                        action: onPreview
                    )

                    reportActionButton(
                        title: "Compartir",
                        icon: "square.and.arrow.up",
                        primary: false,
                        action: onShare
                    )
                }

                reportActionButton(
                    title: "Descargar",
                    icon: "arrow.down.doc",
                    primary: true,
                    action: onDownload
                )
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(
                    AppColors.secondaryText
                )
        }
    }
}

struct ExcelFileIcon: View {

    let size: CGFloat

    var body: some View {

        ZStack {

            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(AppColors.green.opacity(0.12))
                .frame(width: size, height: size)

            VStack(spacing: 5) {

                Image(systemName: "tablecells.fill")
                    .font(
                        .system(
                            size: size * 0.34,
                            weight: .bold
                        )
                    )
                    .foregroundColor(AppColors.green)

                Text("XLSX")
                    .font(
                        .system(
                            size: size * 0.16,
                            weight: .bold
                        )
                    )
                    .foregroundColor(AppColors.green)
            }
        }
    }
}

func reportActionButton(
    title: String,
    icon: String,
    primary: Bool,
    action: @escaping () -> Void
) -> some View {

    Button {

        action()

    } label: {

        HStack(spacing: 8) {

            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundColor(
            primary
            ? .white
            : AppColors.primaryText
        )
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(
            primary
            ? AppColors.primaryText
            : Color.white
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    primary
                    ? Color.clear
                    : Color.gray.opacity(0.18),
                    lineWidth: 1
                )
        )
        .cornerRadius(16)
    }
}