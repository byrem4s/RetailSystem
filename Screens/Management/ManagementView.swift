import SwiftUI

struct ManagementView: View {
    var body: some View {
        NavigationStack {
            ResponsiveScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    PageHeading(
                        eyebrow: "Administración",
                        title: "Gestión",
                        subtitle: (
                            "Usuarios, permisos y configuración operativa "
                            + "de la red de sucursales."
                        )
                    )

                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 260), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        destinationCard(
                            title: "Usuarios",
                            detail: (
                                "Crear encargados o depósito y administrar "
                                + "cuentas existentes."
                            ),
                            icon: "person.2.badge.gearshape",
                            color: AppColors.purple,
                            destination: UserManagementView()
                        )
                        destinationCard(
                            title: "Sucursales",
                            detail: (
                                "Consultar la red, sus perfiles operativos "
                                + "y estado general."
                            ),
                            icon: "building.2",
                            color: AppColors.blue,
                            destination: BranchesView()
                        )
                    }
                }
            }
            .navigationTitle("Gestión")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func destinationCard<Destination: View>(
        title: String,
        detail: String,
        icon: String,
        color: Color,
        destination: Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                IconBadge(systemName: icon, color: color, size: 48)
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(title)
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColors.primaryText)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.tertiaryText)
            }
            .padding(AppSpacing.large)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppSpacing.cardRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppSpacing.cardRadius,
                    style: .continuous
                )
                .stroke(AppColors.subtleBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
