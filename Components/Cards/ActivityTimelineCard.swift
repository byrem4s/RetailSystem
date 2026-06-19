import SwiftUI

struct ActivityTimelineCard: View {

    let item: ActivityEventModel

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 14
        ) {

            VStack(spacing: 0) {

                Circle()
                    .fill(item.color)
                    .frame(width: 10, height: 10)

                Rectangle()
                    .fill(
                        item.color.opacity(0.25)
                    )
                    .frame(width: 2)
            }
            .padding(.top, 24)

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    HStack(alignment: .top) {

                        HStack(spacing: 14) {

                            ZStack {

                                RoundedRectangle(
                                    cornerRadius: 16
                                )
                                .fill(
                                    item.color.opacity(0.12)
                                )
                                .frame(
                                    width: 52,
                                    height: 52
                                )

                                Image(systemName: item.icon)
                                    .foregroundColor(
                                        item.color
                                    )
                            }

                            VStack(
                                alignment: .leading,
                                spacing: 6
                            ) {

                                Text(item.status)
                                    .font(
                                        .system(
                                            size: 11,
                                            weight: .bold
                                        )
                                    )
                                    .foregroundColor(
                                        item.color
                                    )

                                Text(item.title)
                                    .font(
                                        .system(
                                            size: 17,
                                            weight: .semibold
                                        )
                                    )

                                Text(item.branch)
                                    .font(.system(size: 13))
                                    .foregroundColor(
                                        AppColors.secondaryText
                                    )
                            }
                        }

                        Spacer()

                        Text(item.time)
                            .font(.system(size: 12))
                            .foregroundColor(
                                AppColors.secondaryText
                            )
                    }

                    Text(item.reason)
                        .font(.system(size: 13))
                        .foregroundColor(
                            AppColors.secondaryText
                        )

                    HStack {

                        infoBlock(
                            title: "Origen",
                            value: item.origin
                        )

                        Spacer()

                        infoBlock(
                            title: "Destino",
                            value: item.destination
                        )
                    }
                    .padding(14)
                    .background(
                        AppColors.background
                    )
                    .cornerRadius(14)
                }
                .padding(18)
            }
            .background(Color.white)
            .cornerRadius(26)
        }
    }

    func infoBlock(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(
                    AppColors.secondaryText
                )

            Text(value)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
        }
    }
}