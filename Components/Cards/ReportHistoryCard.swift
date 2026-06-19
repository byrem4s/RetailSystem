import SwiftUI

struct ReportHistoryCard: View {

    let item: ReportModel

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 14
        ) {

            ZStack {

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.10))
                    .frame(width: 62, height: 62)

                Image(systemName: "doc.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
            }

            VStack(
                alignment: .leading,
                spacing: 10
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

                HStack(spacing: 14) {

                    Text("\(item.rows) filas")
                    Text("•")
                    Text("\(item.sheets) hojas")
                    Text("•")
                    Text(item.size)
                }
                .font(.system(size: 13))
                .foregroundColor(
                    AppColors.secondaryText
                )

                HStack {

                    Spacer()

                    HStack(spacing: 12) {

                        actionButton(icon: "square.and.arrow.up")

                        actionButton(icon: "arrow.down")
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
    }

    func actionButton(
        icon: String
    ) -> some View {

        Button {

        } label: {

            ZStack {

                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        AppColors.border,
                        lineWidth: 1
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .foregroundColor(
                        AppColors.primaryText
                    )
            }
        }
    }
}