import SwiftUI

struct F8DraftView: View {

    @ObservedObject var vm: F8DraftViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var exportItem: ReportFileItem?

    var body: some View {

        NavigationView {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                if vm.isLoading {

                    ProgressView()
                        .scaleEffect(1.3)

                } else if let draft = vm.draft {

                    ScrollView(showsIndicators: false) {

                        VStack(
                            alignment: .leading,
                            spacing: 18
                        ) {

                            headerCard(
                                draft
                            )

                            validationSummary

                            rowsSection(
                                draft
                            )

                            actionSection(
                                draft
                            )
                        }
                        .padding(18)
                        .padding(.bottom, 30)
                    }

                } else {

                    EmptyStateView(
                        icon: "doc.badge.clock",
                        title: "Sin F8 borrador",
                        message: "Ejecutá un análisis para generar un F8 editable."
                    )
                    .padding()
                }

                if vm.isSaving || vm.isConfirming || vm.isDownloading {

                    Color.black.opacity(0.25)
                        .ignoresSafeArea()

                    VStack(spacing: 12) {

                        ProgressView()
                            .tint(.white)

                        Text(loadingText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("F8 editable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button("Cerrar") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {
                        Task {
                            await vm.refreshCurrentDraft()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await vm.loadLatestDraft()
            }
            .alert(
                "Aviso",
                isPresented: Binding(
                    get: {
                        vm.errorMessage != nil || vm.successMessage != nil
                    },
                    set: { _ in
                        vm.errorMessage = nil
                        vm.successMessage = nil
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    vm.errorMessage = nil
                    vm.successMessage = nil
                }
            } message: {
                Text(
                    vm.errorMessage
                    ?? vm.successMessage
                    ?? ""
                )
            }
            .sheet(
                item: $vm.editingRow
            ) { row in

                F8DraftEditRowSheet(
                    vm: vm,
                    row: row
                )
            }
            .sheet(
                item: $exportItem
            ) { item in

                DocumentExportPicker(
                    url: item.url
                )
            }
        }
    }

    private var loadingText: String {

        if vm.isConfirming {
            return "Confirmando F8..."
        }

        if vm.isDownloading {
            return "Preparando archivo..."
        }

        return "Guardando cambios..."
    }

    private func headerCard(
        _ draft: F8DraftDTO
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Pedido F8")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                    Text("Ejecución #\(draft.executionID)")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                }

                Spacer()

                Text(draft.displayStatus)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(
                        draft.isConfirmed
                        ? AppColors.green
                        : AppColors.orange
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        (
                            draft.isConfirmed
                            ? AppColors.green
                            : AppColors.orange
                        )
                        .opacity(0.12)
                    )
                    .cornerRadius(12)
            }

            HStack(spacing: 14) {

                metricPill(
                    title: "Filas",
                    value: "\(draft.rows.count)"
                )

                metricPill(
                    title: "Unidades",
                    value: "\(draft.rows.reduce(0) { $0 + $1.quantity })"
                )
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
    }

    private var validationSummary: some View {

        Group {

            if let validation = vm.validation {

                HStack(alignment: .top, spacing: 12) {

                    Image(
                        systemName: validation.canConfirm
                        ? "checkmark.circle.fill"
                        : "exclamationmark.triangle.fill"
                    )
                    .foregroundColor(
                        validation.canConfirm
                        ? AppColors.green
                        : AppColors.orange
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(
                            validation.canConfirm
                            ? "F8 listo para confirmar"
                            : "El F8 tiene filas para revisar"
                        )
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)

                        Text(
                            validation.canConfirm
                            ? "Todas las filas pasaron la validación de stock."
                            : "Editá las filas marcadas antes de confirmar."
                        )
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    (
                        validation.canConfirm
                        ? AppColors.green
                        : AppColors.orange
                    )
                    .opacity(0.10)
                )
                .cornerRadius(16)
            }
        }
    }

    private func rowsSection(
        _ draft: F8DraftDTO
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Filas del F8")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            if draft.rows.isEmpty {

                EmptyStateView(
                    icon: "tray",
                    title: "F8 vacío",
                    message: "Todavía no hay filas cargadas."
                )

            } else {

                VStack(spacing: 12) {

                    ForEach(draft.rows) { row in

                        rowCard(
                            row,
                            isConfirmed: draft.isConfirmed
                        )
                    }
                }
            }
        }
    }

    private func rowCard(
        _ row: F8DraftRowDTO,
        isConfirmed: Bool
    ) -> some View {

        let validation = vm.validationForRow(
            row
        )

        return VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(alignment: .top) {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(row.code)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                    Text(row.description.isEmpty ? "Sin descripción" : row.description)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                Text("\(row.quantity) u.")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.blue.opacity(0.10))
                    .cornerRadius(10)
            }

            VStack(spacing: 8) {

                detailLine(
                    title: "Origen",
                    value: row.origin
                )

                detailLine(
                    title: "Destino",
                    value: row.destination
                )

                detailLine(
                    title: "Talle",
                    value: row.size
                )
            }

            if let validation,
               !validation.isValid {

                HStack(alignment: .top, spacing: 8) {

                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.orange)

                    Text(validation.message)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(AppColors.orange.opacity(0.10))
                .cornerRadius(12)
            }

            if !isConfirmed {

                HStack(spacing: 10) {

                    Button {

                        vm.editingRow = row

                    } label: {

                        Text("Editar")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(AppColors.blue.opacity(0.10))
                            .cornerRadius(14)
                    }

                    Button(role: .destructive) {

                        Task {
                            await vm.deleteRow(
                                row: row
                            )
                        }

                    } label: {

                        Text("Eliminar")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(AppColors.red.opacity(0.10))
                            .cornerRadius(14)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
    }

    private func actionSection(
        _ draft: F8DraftDTO
    ) -> some View {

        VStack(spacing: 12) {

            if draft.isConfirmed {

                Button {

                    Task {

                        if let url = await vm.downloadConfirmedFile() {

                            exportItem = ReportFileItem(
                                url: url
                            )
                        }
                    }

                } label: {

                    HStack(spacing: 8) {

                        Image(systemName: "square.and.arrow.down")

                        Text("Descargar F8 confirmado")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.green)
                    .cornerRadius(16)
                }

            } else {

                Button {

                    Task {
                        await vm.confirmDraft()
                    }

                } label: {

                    HStack(spacing: 8) {

                        Image(systemName: "checkmark.seal.fill")

                        Text("Confirmar F8")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        vm.canConfirm
                        ? AppColors.green
                        : Color.gray.opacity(0.55)
                    )
                    .cornerRadius(16)
                }
                .disabled(!vm.canConfirm)
            }
        }
    }

    private func detailLine(
        title: String,
        value: String
    ) -> some View {

        HStack {

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.secondaryText)

            Spacer()

            Text(value.isEmpty ? "-" : value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func metricPill(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 3
        ) {

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(AppColors.secondaryText)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.background)
        .cornerRadius(14)
    }
}

struct F8DraftEditRowSheet: View {

    @ObservedObject var vm: F8DraftViewModel

    let row: F8DraftRowDTO

    @Environment(\.dismiss) private var dismiss

    @State private var origin: String
    @State private var destination: String
    @State private var size: String
    @State private var quantity: Int

    init(
        vm: F8DraftViewModel,
        row: F8DraftRowDTO
    ) {

        self.vm = vm
        self.row = row

        _origin = State(
            initialValue: row.origin
        )

        _destination = State(
            initialValue: row.destination
        )

        _size = State(
            initialValue: row.size
        )

        _quantity = State(
            initialValue: max(row.quantity, 1)
        )
    }

    private var maxQuantity: Int {

        max(
            vm.selectedRowOptions?.validation.maxQuantity
            ?? quantity,
            1
        )
    }

    var body: some View {

        NavigationView {

            ScrollView(showsIndicators: false) {

                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {

                    Text(row.code)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                    originPicker

                    destinationPicker

                    sizePicker

                    quantityEditor

                    if let validation = vm.selectedRowOptions?.validation {

                        validationMessage(
                            validation
                        )
                    }

                    Button {

                        Task {

                            let success = await vm.updateRow(
                                row: row,
                                origin: origin,
                                destination: destination,
                                size: size,
                                quantity: quantity
                            )

                            if success {
                                dismiss()
                            }
                        }

                    } label: {

                        Text(vm.isSaving ? "Guardando..." : "Guardar cambios")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColors.blue)
                            .cornerRadius(16)
                    }
                    .disabled(vm.isSaving)
                }
                .padding(18)
            }
            .background(AppColors.background)
            .navigationTitle("Editar fila")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .task {
                await vm.loadOptions(
                    row: row
                )
            }
        }
    }

    private var originPicker: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Origen")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)

            Menu {

                ForEach(vm.selectedRowOptions?.origins ?? []) { option in

                    Button {

                        origin = option.origin

                        if quantity > option.availableQuantity {
                            quantity = max(option.availableQuantity, 1)
                        }

                    } label: {

                        Text(
                            "\(option.origin) · disponible \(option.availableQuantity)"
                        )
                    }
                }

            } label: {

                pickerLabel(
                    origin.isEmpty ? "Seleccionar origen" : origin
                )
            }
        }
    }

    private var destinationPicker: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Destino")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)

            Menu {

                ForEach(
                    vm.selectedRowOptions?.destinations ?? [],
                    id: \.self
                ) { item in

                    Button(item) {
                        destination = item
                    }
                }

            } label: {

                pickerLabel(
                    destination.isEmpty ? "Seleccionar destino" : destination
                )
            }
        }
    }

    private var sizePicker: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Talle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)

            Menu {

                ForEach(
                    vm.selectedRowOptions?.sizes ?? [],
                    id: \.self
                ) { item in

                    Button(item) {
                        size = item
                    }
                }

            } label: {

                pickerLabel(
                    size.isEmpty ? "Seleccionar talle" : size
                )
            }
        }
    }

    private var quantityEditor: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Cantidad")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)

            HStack {

                Button {

                    quantity = max(
                        quantity - 1,
                        1
                    )

                } label: {

                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.blue)
                }

                Spacer()

                Text("\(quantity)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.primaryText)

                Spacer()

                Button {

                    quantity = min(
                        quantity + 1,
                        maxQuantity
                    )

                } label: {

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.blue)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)

            Text("Máximo disponible: \(maxQuantity)")
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)
        }
    }

    private func pickerLabel(
        _ text: String
    ) -> some View {

        HStack {

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.primaryText)

            Spacer()

            Image(systemName: "chevron.down")
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    private func validationMessage(
        _ validation: F8DraftRowValidationDetailDTO
    ) -> some View {

        HStack(alignment: .top, spacing: 8) {

            Image(
                systemName: validation.isValid
                ? "checkmark.circle.fill"
                : "exclamationmark.triangle.fill"
            )
            .foregroundColor(
                validation.isValid
                ? AppColors.green
                : AppColors.orange
            )

            Text(validation.message)
                .font(.system(size: 13))
                .foregroundColor(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            (
                validation.isValid
                ? AppColors.green
                : AppColors.orange
            )
            .opacity(0.10)
        )
        .cornerRadius(14)
    }
}