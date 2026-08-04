import SwiftUI

struct RequiredPasswordChangeView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var temporaryPassword = ""
    @State private var newPassword = ""
    @State private var confirmation = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppSpacing.large) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 76, height: 76)
                            .background(AppColors.blue)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 22,
                                    style: .continuous
                                )
                            )

                        VStack(spacing: AppSpacing.small) {
                            Text("Protegé tu cuenta")
                                .font(AppTypography.pageTitle)
                            Text(
                                "Ingresaste con una contraseña temporal. "
                                + "Creá una nueva para continuar."
                            )
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                        }

                        AppCard {
                            VStack(spacing: AppSpacing.regular) {
                                SecureField(
                                    "Contraseña temporal",
                                    text: $temporaryPassword
                                )
                                .textContentType(.password)
                                .appTextField()

                                SecureField(
                                    "Nueva contraseña",
                                    text: $newPassword
                                )
                                .textContentType(.newPassword)
                                .appTextField()

                                SecureField(
                                    "Repetir nueva contraseña",
                                    text: $confirmation
                                )
                                .textContentType(.newPassword)
                                .appTextField()

                                Text(
                                    "Usá al menos 12 caracteres. La contraseña "
                                    + "nueva debe ser diferente de la temporal."
                                )
                                .font(.caption)
                                .foregroundStyle(AppColors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                if let error = session.errorMessage {
                                    Label(
                                        error,
                                        systemImage: "exclamationmark.triangle.fill"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(AppColors.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                Button {
                                    Task { await submit() }
                                } label: {
                                    HStack {
                                        if session.isWorking {
                                            ProgressView().tint(.white)
                                        } else {
                                            Image(systemName: "checkmark.shield.fill")
                                        }
                                        Text(
                                            session.isWorking
                                                ? "Actualizando…"
                                                : "Guardar y continuar"
                                        )
                                    }
                                }
                                .buttonStyle(PrimaryActionButtonStyle())
                                .disabled(!isValid || session.isWorking)
                                .opacity(isValid ? 1 : 0.5)
                            }
                        }

                        Button("Cerrar sesión", role: .destructive) {
                            Task { await session.logout() }
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: 520)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 36)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var isValid: Bool {
        temporaryPassword.count >= 12
            && newPassword.count >= 12
            && newPassword == confirmation
            && newPassword != temporaryPassword
    }

    private func submit() async {
        _ = await session.changeRequiredPassword(
            currentPassword: temporaryPassword,
            newPassword: newPassword
        )
    }
}
