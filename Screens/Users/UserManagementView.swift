import SwiftUI

struct UserManagementView: View {

    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = UserManagementViewModel()
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.users.isEmpty {
                    ProgressView("Cargando usuarios…")
                } else {
                    List(viewModel.users) { user in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(
                                        AppColors.secondaryText
                                    )
                                Text(user.role.displayName)
                                    .font(.caption)
                                    .foregroundColor(AppColors.blue)
                            }
                            Spacer()
                            Button(
                                user.active ? "Desactivar" : "Activar",
                                role: user.active ? .destructive : nil
                            ) {
                                Task {
                                    await viewModel.toggle(user)
                                }
                            }
                            .disabled(!canModify(user))
                        }
                        .padding(.vertical, 4)
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("Usuarios")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Label("Agregar", systemImage: "person.badge.plus")
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .sheet(isPresented: $showingCreate) {
                CreateUserSheet(
                    availableRoles: availableRoles,
                    branches: viewModel.branches
                ) { email, password, firstName, lastName, role, branchID in
                    let created = await viewModel.create(
                        email: email,
                        password: password,
                        firstName: firstName,
                        lastName: lastName,
                        role: role,
                        branchID: branchID
                    )
                    if created {
                        showingCreate = false
                    }
                }
            }
            .alert(
                "No se pudo completar",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: {
                        if !$0 {
                            viewModel.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var availableRoles: [UserRole] {
        if session.user?.role == .systemOwner {
            return [
                .companyAdmin,
                .branchManager,
                .warehouse
            ]
        }
        return [.branchManager, .warehouse]
    }

    private func canModify(_ user: AuthUserDTO) -> Bool {
        guard !user.protected else {
            return false
        }
        if session.user?.role == .companyAdmin {
            return ![
                UserRole.systemOwner,
                UserRole.companyAdmin
            ].contains(user.role)
        }
        return user.role != .systemOwner
    }
}

private struct CreateUserSheet: View {

    let availableRoles: [UserRole]
    let branches: [BranchV2DTO]
    let onCreate: (
        String,
        String,
        String,
        String,
        UserRole,
        Int?
    ) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var role: UserRole
    @State private var branchID: Int?
    @State private var isSaving = false

    init(
        availableRoles: [UserRole],
        branches: [BranchV2DTO],
        onCreate: @escaping (
            String,
            String,
            String,
            String,
            UserRole,
            Int?
        ) async -> Void
    ) {
        self.availableRoles = availableRoles
        self.branches = branches
        self.onCreate = onCreate
        _role = State(
            initialValue: availableRoles.first ?? .branchManager
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Persona") {
                    TextField("Nombre", text: $firstName)
                    TextField("Apellido", text: $lastName)
                    TextField("Correo", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField(
                        "Contraseña de al menos 12 caracteres",
                        text: $password
                    )
                }
                Section("Permisos") {
                    Picker("Rol", selection: $role) {
                        ForEach(availableRoles, id: \.rawValue) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    if role == .branchManager {
                        Picker("Sucursal", selection: $branchID) {
                            Text("Seleccionar").tag(Int?.none)
                            ForEach(branches) { branch in
                                Text(branch.name).tag(Int?.some(branch.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nuevo usuario")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Guardando…" : "Crear") {
                        isSaving = true
                        Task {
                            await onCreate(
                                email,
                                password,
                                firstName,
                                lastName,
                                role,
                                role == .branchManager
                                    ? branchID
                                    : nil
                            )
                            isSaving = false
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private var isValid: Bool {
        !email.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        && password.count >= 12
        && !firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        && !lastName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        && (role != .branchManager || branchID != nil)
    }
}
