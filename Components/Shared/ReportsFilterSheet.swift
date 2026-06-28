import SwiftUI

struct ReportsFilterSheet: View {

    @Binding var selectedReportType: String
    @Binding var selectedReportStatus: String
    @Binding var searchText: String
    @Binding var isDateFilterEnabled: Bool
    @Binding var selectedDate: Date

    let reportTypeOptions: [String]
    let reportStatusOptions: [String]

    let onApply: () -> Void
    let onClear: () -> Void

    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {

        NavigationView {

            ScrollView(showsIndicators: false) {

                VStack(
                    alignment: .leading,
                    spacing: 22
                ) {

                    searchSection

                    typeSection

                    statusSection

                    dateSection

                    actionsSection
                }
                .padding(18)
            }
            .background(AppColors.background)
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var searchSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Buscar")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            TextField(
                "Nombre de archivo, F8, análisis, run...",
                text: $searchText
            )
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
        }
    }

    private var typeSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Tipo de reporte")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            Picker(
                "Tipo",
                selection: $selectedReportType
            ) {

                ForEach(
                    reportTypeOptions,
                    id: \.self
                ) { option in

                    Text(option)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var statusSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Estado")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            Picker(
                "Estado",
                selection: $selectedReportStatus
            ) {

                ForEach(
                    reportStatusOptions,
                    id: \.self
                ) { option in

                    Text(option)
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(16)
        }
    }

    private var dateSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Toggle(
                "Filtrar por fecha",
                isOn: $isDateFilterEnabled
            )
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(AppColors.primaryText)

            if isDateFilterEnabled {

                DatePicker(
                    "Fecha",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .background(Color.white)
                .cornerRadius(24)
            }
        }
    }

    private var actionsSection: some View {

        VStack(spacing: 12) {

            Button {

                onApply()
                dismiss()

            } label: {

                Text("Aplicar filtros")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.blue)
                    .cornerRadius(16)
            }

            Button {

                onClear()
                dismiss()

            } label: {

                Text("Limpiar filtros")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.blue.opacity(0.10))
                    .cornerRadius(16)
            }
        }
    }
}