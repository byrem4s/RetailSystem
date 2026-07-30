import SwiftUI

struct BranchesView: View {
    @State private var branches: [BranchV2DTO] = []
    @State private var searchText = ""
    @State private var selectedGroup = "TODAS"
    @State private var selectedBranch: BranchV2DTO?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service = UserManagementService()

    var body: some View {
        ZStack {
            ResponsiveScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    PageHeading(
                        eyebrow: "Catálogo operativo",
                        title: "Sucursales",
                        subtitle: (
                            "Consultá la configuración que usa el análisis "
                            + "para cada ubicación."
                        )
                    )

                    searchAndFilter

                    if isLoading && branches.isEmpty {
                        ProgressView("Cargando sucursales…")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.section)
                    } else if filteredBranches.isEmpty {
                        AppCard {
                            ContentUnavailableView.search(text: searchText)
                        }
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(
                                    .adaptive(minimum: 255),
                                    spacing: 12
                                )
                            ],
                            spacing: 12
                        ) {
                            ForEach(filteredBranches) { branch in
                                branchCard(branch)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Sucursales")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .task { await load() }
        .sheet(item: $selectedBranch) { branch in
            BranchDetailSheet(branch: branch)
                .presentationDetents([.medium, .large])
        }
        .alert(
            "No se pudieron cargar las sucursales",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var searchAndFilter: some View {
        VStack(spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.secondaryText)
                TextField("Buscar por nombre o código", text: $searchText)
                    .textInputAutocapitalization(.never)
            }
            .appTextField()

            Picker("Grupo", selection: $selectedGroup) {
                ForEach(groups, id: \.self) { group in
                    Text(groupLabel(group)).tag(group)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func branchCard(_ branch: BranchV2DTO) -> some View {
        Button {
            selectedBranch = branch
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack {
                    IconBadge(
                        systemName: branchIcon(branch),
                        color: groupColor(branch.businessGroup)
                    )
                    Spacer()
                    if branch.isOutlet {
                        StatusPill(
                            title: "OUTLET",
                            color: AppColors.orange
                        )
                    } else if branch.isDepot {
                        StatusPill(
                            title: "DEPÓSITO",
                            color: AppColors.purple
                        )
                    } else if branch.salesChannel == "ONLINE" {
                        StatusPill(
                            title: "ONLINE",
                            color: AppColors.cyan
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(branch.name)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.primaryText)
                    Text(branch.code)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }

                HStack {
                    Label(
                        groupLabel(branch.businessGroup),
                        systemImage: "tag"
                    )
                    Spacer()
                    Text(branch.discipline.capitalized)
                }
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
            }
            .padding(AppSpacing.regular)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
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

    private var groups: [String] {
        let values = Set(
            branches
                .map(\.businessGroup)
                .filter { !$0.isEmpty }
        )
        return ["TODAS"] + values.sorted()
    }

    private var filteredBranches: [BranchV2DTO] {
        branches.filter { branch in
            let matchesGroup = selectedGroup == "TODAS"
                || branch.businessGroup == selectedGroup
            let query = searchText
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || branch.name.localizedCaseInsensitiveContains(query)
                || branch.code.localizedCaseInsensitiveContains(query)
            return matchesGroup && matchesSearch
        }
    }

    private func branchIcon(_ branch: BranchV2DTO) -> String {
        if branch.isDepot { return "shippingbox.fill" }
        if branch.salesChannel == "ONLINE" { return "cart.fill" }
        if branch.isOutlet { return "tag.fill" }
        return "building.2.fill"
    }

    private func groupLabel(_ group: String) -> String {
        group == "TODAS" ? "Todas" : group.capitalized
    }

    private func groupColor(_ group: String) -> Color {
        switch group {
        case "ADIDAS": return AppColors.blue
        case "AURELIUS": return AppColors.purple
        case "ECOMMERCE": return AppColors.cyan
        default: return AppColors.green
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            branches = try await service.fetchBranches()
            if !groups.contains(selectedGroup) {
                selectedGroup = "TODAS"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct BranchDetailSheet: View {
    let branch: BranchV2DTO
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Identidad") {
                    LabeledContent("Nombre", value: branch.name)
                    LabeledContent("Código", value: branch.code)
                    LabeledContent(
                        "Grupo",
                        value: branch.businessGroup.capitalized
                    )
                    LabeledContent(
                        "Tipo",
                        value: branch.branchType.capitalized
                    )
                }
                Section("Operación") {
                    LabeledContent(
                        "Canal",
                        value: branch.salesChannel.capitalized
                    )
                    LabeledContent(
                        "Disciplina",
                        value: branch.discipline.capitalized
                    )
                    LabeledContent(
                        "Días de apertura",
                        value: "\(branch.workingDays.count) por semana"
                    )
                    LabeledContent(
                        "Peso de demanda",
                        value: branch.demandWeight.formatted(
                            .number.precision(.fractionLength(2))
                        )
                    )
                }
                Section("Público") {
                    LabeledContent(
                        "Adulto",
                        value: branch.acceptsAdult ? "Sí" : "No"
                    )
                    LabeledContent(
                        "Niños",
                        value: branch.acceptsKids ? "Sí" : "No"
                    )
                    if branch.acceptsKids {
                        LabeledContent(
                            "Perfil kids",
                            value: branch.kidsProfile.capitalized
                        )
                    }
                }
            }
            .navigationTitle(branch.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
