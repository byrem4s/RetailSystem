import SwiftUI

struct AlertOperationalCard: View {

    let item: OperationalAlertModel

    var body: some View {

        VStack(spacing: 0) {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                HStack(alignment: .top) {

                    HStack(spacing: 14) {

                        ZStack {

                            RoundedRectangle(cornerRadius: 14)
                                .fill(item.color.opacity(0.12))
                                .frame(width: 52, height: 52)

                            Image(systemName: item.icon)
                                .foregroundColor(item.color)
                                .font(.system(size: 18))
                        }

                        VStack(
                            alignment: .leading,
                            spacing: 6
                        ) {

                            Text(item.subtitle)
                                .font(
                                    .system(
                                        size: 11,
                                        weight: .bold
                                    )
                                )
                                .foregroundColor(item.color)

                            Text(item.title)
                                .font(
                                    .system(
                                        size: 18,
                                        weight: .semibold
                                    )
                                )

                            HStack(spacing: 6) {

                                Image(systemName: "building.2")

                                Text(item.branch)
                            }
                            .font(.system(size: 12))
                            .foregroundColor(
                                AppColors.secondaryText
                            )
                        }
                    }

                    Spacer()

                    VStack(
                        alignment: .trailing,
                        spacing: 10
                    ) {

                        Text(item.time)
                            .font(.system(size: 12))
                            .foregroundColor(
                                AppColors.secondaryText
                            )

                        Text(item.risk)
                            .font(
                                .system(
                                    size: 11,
                                    weight: .medium
                                )
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                item.color.opacity(0.12)
                            )
                            .foregroundColor(item.color)
                            .cornerRadius(12)
                    }
                }

                Divider()

                HStack {

                    metricBlock(
                        title: "Vendió",
                        value: item.sold
                    )

                    Spacer()

                    metricBlock(
                        title: "Stock",
                        value: item.stock,
                        highlight: true
                    )

                    Spacer()

                    metricBlock(
                        title: "Velocidad",
                        value: item.velocity
                    )

                    Spacer()

                    metricBlock(
                        title: "Necesidad",
                        value: item.needed,
                        highlight: true
                    )
                }

                Divider()

                Text(item.description)
                    .font(.system(size: 13))
                    .foregroundColor(
                        AppColors.secondaryText
                    )

                HStack(spacing: 12) {

                    Button {

                    } label: {

                        HStack {

                            Image(systemName: "eye")

                            Text("Ver detalle")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    Color.gray.opacity(0.2)
                                )
                        )
                    }

                    Button {

                    } label: {

                        HStack {

                            Text("Tomar acción")

                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(item.color)
                        .cornerRadius(14)
                    }
                }
            }
            .padding(18)
        }
        .background(AppColors.card)
        .cornerRadius(26)
    }

    func metricBlock(
        title: String,
        value: String,
        highlight: Bool = false
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(
                    AppColors.secondaryText
                )

            Text(value)
                .font(
                    .system(
                        size: 17,
                        weight: .bold
                    )
                )
                .foregroundColor(
                    highlight
                    ? item.color
                    : AppColors.primaryText
                )
        }
    }
}