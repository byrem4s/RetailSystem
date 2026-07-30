import SwiftUI

struct UserManagementView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = UserManagementViewModel()
    @State private var showingCreate = false
    @State private var searchText = ""
    @State private var showsInactive = true

    var body: some View {
        ZStack {
            ResponsiveScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    PageHeading(
                        eyebrow: "Accesos",
                        title: "Usuarios",
                        subtitle: (
                            "Cada cuenta tiene un rol explícito. Los encargados "
                            + "sólo ven la sucursal asignada."
                        )
                    )

                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.secondaryText)
                        TextField(
                            "Buscar por nombre o correo",
                            text: $searchText
                        )
                        .textInputAutocapitalization(.never)
                    }
                    .appTextField()

                    Toggle("Mostrar cuentas inactivas", isOn: $showsInactive)
                        .font(.subheadline.weight(.medium))
                        .tint(AppColors.blue)

                    if viewModel.isLoading && viewModel.users.isEmpty {
                        ProgressView("Cargando usuarios…")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.section)
                    } else if filteredUsers.isEmpty {
                        AppCard {
                            ContentUnavailableView.search(text: searchText)
                        }
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(
                                    .adaptive(minimum: 285),
                                    spacing: 12
                                )
                            ],
                            spacing: 12
                        ) {
                            ForEach(filteredUsers) { user in
                                userCard(user)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Usuarios")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreate = true
                } label: {
                    Label("Agregar", systemImage: "person.badge.plus")
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
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
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func userCard(_ user: AuthUserDTO) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.regular) {
                HStack(alignment: .top) {
                    Text(initials(user))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(roleColor(user.role))
                        .frame(width: 44, height: 44)
                        .background(roleColor(user.role).opacity(0.12))
                        .clipShape(Circle())
                    Spacer()
                    StatusPill(
                        title: user.active ? "ACTIVO" : "INACTIVO",
                        color: user.active
                            ? AppColors.green
                            : AppColors.secondaryText
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.fullName)
                        .font(AppTypography.cardTitle)
                    Text(user.email)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Label(
                    user.role.displayName,
                    systemImage: roleIcon(user.role)
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(roleColor(user.role))

                Divider()

                if canModify(user) {
                    Button(
                        user.active ? "Desactivar cuenta" : "Activar cuenta",
                        role: user.active ? .destructive : nil
                    ) {
                        Task { await viewModel.toggle(user) }
                    }
                    .font(.subheadline.weight(.semibold))
                } else {
                    Label(
                        "Cuenta protegida",
                        systemImage: "lock.shield"
                    )
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }

    private var filteredUsers: [AuthUserDTO] {
        viewModel.users.filter { user in
            guard showsInactive || user.active else { return false }
            let query = searchText
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return query.isEmpty
                || user.fullName.localizedCaseInsensitiveContains(query)
                || user.email.localizedCaseInsensitiveContains(query)
        }
    }

    private var availableRoles: [UserRole] {
        if session.user?.role == .systemOwner {
            return [.companyAdmin, .branchManager, .warehouse]
        }
        return [.branchManager, .warehouse]
    }

    private func canModify(_ user: AuthUserDTO) -> Bool {
        guard !user.protected else { return false }
        if session.user?.role == .companyAdmin {
            return ![
                UserRole.systemOwner,
                UserRole.companyAdmin
            ].contains(user.role)
        }
        return user.role != .systemOwner
    }

    private func initials(_ user: AuthUserDTO) -> String {
        let first = user.firstName.first.map(String.init) ?? ""
        let last = user.lastName.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    private func roleIcon(_ role: UserRole) -> String {
        switch role {
        case .systemOwner: return "crown.fill"
        case .companyAdmin: return "person.crop.circle.badge.checkmark"
        case .branchManager: return "storefront"
        case .warehouse: return "shippingbox.fill"
        }
    }

    private func roleColor(_ role: UserRole) -> Color {
        switch role {
        case .systemOwner: return AppColors.purple
        case .companyAdmin: return AppColors.blue
        case .branchManager: return AppColors.green
        case .warehouse: return AppColors.orange
        }
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
                        .textContentType(.givenName)
                    TextField("Apellido", text: $lastName)
                        .textContentType(.familyName)
                    TextField("Correo", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    SecureField(
                        "Contraseña de al menos 12 caracteres",
                        text: $password
                    )
                    .textContentType(.newPassword)
                }

                Section {
                    Picker("Rol", selection: $role) {
                        ForEach(availableRoles, id: \.rawValue) { value in
                            Text(value.displayName).tag(value)
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
                } header: {
                    Text("Permisos")
                } footer: {
                    Text(permissionDescription)
                }
            }
            .navigationTitle("Nuevo usuario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
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
                                role == .branchManager ? branchID : nil
                            )
                            isSaving = false
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private var permissionDescription: String {
        switch role {
        case .companyAdmin:
            return "Accede a la operación global, excepto crear otros administradores."
        case .branchManager:
            return "Sólo ve solicitudes y movimientos de la sucursal asignada."
        case .warehouse:
            return "Opera aprobaciones, preparación, despacho y recepción."
        case .systemOwner:
            return "Acceso total."
        }
    }

    private var isValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
