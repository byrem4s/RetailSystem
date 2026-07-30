import SwiftUI

struct LoginView: View {

    @EnvironmentObject private var session: SessionStore

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.blue)

                    Text("Reposición Mateu")
                        .font(.system(size: 28, weight: .bold))

                    Text(
                        "Ingresá con el usuario asignado por la empresa."
                    )
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    TextField("Correo", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .padding()
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let message = session.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task {
                        await session.login(
                            email: email,
                            password: password
                        )
                    }
                } label: {
                    HStack {
                        if session.isWorking {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(
                            session.isWorking
                                ? "Ingresando…"
                                : "Ingresar"
                        )
                        .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(AppColors.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(
                    email.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                    || password.isEmpty
                    || session.isWorking
                )

                Spacer()
            }
            .padding(24)
            .background(AppColors.background.ignoresSafeArea())
        }
    }
}
