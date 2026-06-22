import SwiftUI

struct ReportHistoryCard: View {

    let item: ReportModel

    let onPreview: () -> Void
    let onShare: () -> Void
    let onDownload: () -> Void

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 14
        ) {

            ExcelFileIcon(
                size: 62
            )

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                HStack(alignment: .top) {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text(item.fileName)
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold
                                )
                            )
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        Text(
                            "\(item.date) • \(item.type)"
                        )
                        .font(.system(size: 13))
                        .foregroundColor(
                            AppColors.secondaryText
                        )
                    }

                    Spacer()

                    Text(item.status)
                        .font(
                            .system(
                                size: 12,
                                weight: .medium
                            )
                        )
                        .foregroundColor(item.statusColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            item.statusColor.opacity(0.12)
                        )
                        .cornerRadius(12)
                }

                HStack(spacing: 8) {

                    Text("\(item.sheets) hojas")

                    Text("•")

                    Text(item.size)
                }
                .font(.system(size: 13))
                .foregroundColor(
                    AppColors.secondaryText
                )

                HStack(spacing: 10) {

                    compactActionButton(
                        icon: "eye",
                        action: onPreview
                    )

                    compactActionButton(
                        icon: "square.and.arrow.up",
                        action: onShare
                    )

                    compactActionButton(
                        icon: "arrow.down.doc",
                        action: onDownload
                    )

                    Spacer()
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }

    func compactActionButton(
        icon: String,
        action: @escaping () -> Void
    ) -> some View {

        Button {

            action()

        } label: {

            ZStack {

                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        Color.gray.opacity(0.18),
                        lineWidth: 1
                    )
                    .frame(width: 44, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(
                        AppColors.primaryText
                    )
            }
        }
    }
}