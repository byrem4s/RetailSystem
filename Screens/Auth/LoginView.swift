import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var email = ""
    @State private var password = ""
    @State private var showsPassword = false
    @State private var showsRecovery = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        ZStack {
            AppColors.brandGradient
                .ignoresSafeArea()

            Circle()
                .fill(AppColors.cyan.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 2)
                .offset(x: 190, y: -330)

            ScrollView {
                VStack(spacing: horizontalSizeClass == .regular ? 40 : 28) {
                    brandBlock
                    loginCard
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, horizontalSizeClass == .regular ? 72 : 36)
                .frame(maxWidth: .infinity, minHeight: 700)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                submit()
            case nil:
                break
            }
        }
        .sheet(isPresented: $showsRecovery) {
            PasswordRecoveryView(initialEmail: email)
        }
    }

    private var brandBlock: some View {
        VStack(spacing: AppSpacing.regular) {
            HStack(spacing: AppSpacing.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(.white)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppColors.blue)
                }
                .frame(width: 62, height: 62)
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("MATEU")
                        .font(.system(.title, design: .rounded, weight: .black))
                        .tracking(1.6)
                    Text("OPERACIONES")
                        .font(.caption.weight(.bold))
                        .tracking(2.1)
                        .opacity(0.72)
                }
                .foregroundStyle(.white)
            }

            VStack(spacing: AppSpacing.small) {
                Text("Reposición inteligente,\nsin planillas cruzadas.")
                    .font(
                        .system(
                            horizontalSizeClass == .regular
                                ? .largeTitle
                                : .title,
                            design: .rounded,
                            weight: .bold
                        )
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(
                    "Ventas, stock y movimientos entre sucursales "
                    + "en un único circuito."
                )
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: 410)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Bienvenido")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                Text("Ingresá con el usuario asignado por la empresa.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }

            VStack(alignment: .leading, spacing: AppSpacing.regular) {
                loginField(
                    title: "Correo electrónico",
                    icon: "envelope",
                    content: {
                        TextField("nombre@empresa.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.username)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                    }
                )

                loginField(
                    title: "Contraseña",
                    icon: "lock",
                    content: {
                        Group {
                            if showsPassword {
                                TextField("Tu contraseña", text: $password)
                            } else {
                                SecureField("Tu contraseña", text: $password)
                            }
                        }
                        .textContentType(.password)
                        .submitLabel(.go)
                        .focused($focusedField, equals: .password)

                        Button {
                            showsPassword.toggle()
                        } label: {
                            Image(
                                systemName: showsPassword
                                    ? "eye.slash"
                                    : "eye"
                            )
                            .foregroundStyle(AppColors.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            showsPassword
                                ? "Ocultar contraseña"
                                : "Mostrar contraseña"
                        )
                    }
                )
            }

            if let message = session.errorMessage {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label(
                        message,
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(AppColors.red)
                    .fixedSize(horizontal: false, vertical: true)

                    Text("Servidor configurado: \(AppEnvironment.baseURL)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(AppColors.secondaryText)
                        .textSelection(.enabled)
                }
            } else if session.isWorking {
                Text("Conectando con \(AppEnvironment.baseURL)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Button(action: submit) {
                HStack(spacing: AppSpacing.small) {
                    if session.isWorking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right")
                    }
                    Text(session.isWorking ? "Ingresando…" : "Ingresar")
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.52)

            Button("¿Olvidaste tu contraseña?") {
                showsRecovery = true
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)

            Label(
                "El acceso y cada acción quedan registrados.",
                systemImage: "checkmark.shield"
            )
            .font(.caption)
            .foregroundStyle(AppColors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(horizontalSizeClass == .regular ? 32 : 24)
        .background(AppColors.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.20), radius: 30, y: 18)
    }

    private func loginField<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.blue)
                    .frame(width: 20)
                content()
            }
            .appTextField()
        }
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
            && !session.isWorking
    }

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 40 : 20
    }

    private func submit() {
        guard canSubmit else { return }
        focusedField = nil
        Task {
            await session.login(email: email, password: password)
        }
    }
}

private struct PasswordRecoveryView: View {
    let initialEmail: String
    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var message: String?
    @State private var errorMessage: String?
    @State private var isWorking = false

    private let service = AuthService()

    init(initialEmail: String) {
        self.initialEmail = initialEmail
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Correo", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                    Button("Solicitar restablecimiento") {
                        Task { await requestReset() }
                    }
                    .disabled(email.isEmpty || isWorking)
                } header: {
                    Text("Solicitar ayuda")
                } footer: {
                    Text(
                        "Un administrador recibirá la solicitud y te dará "
                        + "una contraseña temporal. Al ingresar deberás cambiarla."
                    )
                }

                if let message {
                    Section {
                        Label(message, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.green)
                    }
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(AppColors.red)
                    }
                }
            }
            .navigationTitle("Recuperar contraseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private func requestReset() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let result = try await service.forgotPassword(email: email)
            message = result.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
