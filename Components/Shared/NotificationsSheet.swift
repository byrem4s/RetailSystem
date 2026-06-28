import SwiftUI

struct NotificationsSheet: View {

    @ObservedObject var vm: NotificationViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        NavigationView {

            ZStack {

                ScrollView(showsIndicators: false) {

                    VStack(
                        alignment: .leading,
                        spacing: 18
                    ) {

                        summarySection

                        notificationsSection
                    }
                    .padding(18)
                    .padding(.bottom, 24)
                }

                if vm.isLoading {

                    Color.black.opacity(0.18)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.3)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Notificaciones")
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

                    Button("Leer todo") {
                        Task {
                            await vm.markAllAsRead()
                        }
                    }
                    .disabled(vm.unreadCount == 0)
                }
            }
            .task {
                await vm.loadNotifications()
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { vm.errorMessage != nil },
                    set: { _ in vm.errorMessage = nil }
                )
            ) {
                Button("OK") {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private var summarySection: some View {

        HStack(spacing: 12) {

            summaryCard(
                title: "No leídas",
                value: "\(vm.summary?.unread ?? vm.unreadCount)",
                color: AppColors.orange
            )

            summaryCard(
                title: "Críticas",
                value: "\(vm.summary?.critical ?? 0)",
                color: AppColors.red
            )

            summaryCard(
                title: "Total",
                value: "\(vm.summary?.total ?? 0)",
                color: AppColors.blue
            )
        }
    }

    private func summaryCard(
        title: String,
        value: String,
        color: Color
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(18)
    }

    private var notificationsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Historial")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.primaryText)

            if vm.notifications.isEmpty {

                EmptyStateView(
                    icon: "bell",
                    title: "Sin notificaciones",
                    message: "Todavía no hay notificaciones del sistema."
                )

            } else {

                VStack(spacing: 12) {

                    ForEach(vm.notifications) { item in

                        notificationRow(
                            item
                        )
                    }
                }
            }
        }
    }

    private func notificationRow(
        _ item: NotificationDTO
    ) -> some View {

        Button {

            Task {
                await vm.markAsRead(
                    item
                )
            }

        } label: {

            HStack(
                alignment: .top,
                spacing: 12
            ) {

                ZStack {

                    RoundedRectangle(cornerRadius: 14)
                        .fill(notificationColor(item).opacity(0.12))
                        .frame(width: 46, height: 46)

                    Image(systemName: notificationIcon(item))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(notificationColor(item))
                }

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    HStack {

                        Text(notificationLabel(item))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(notificationColor(item))

                        Spacer()

                        Text(item.time)
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.secondaryText)
                    }

                    Text(item.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                    if let message = item.message,
                       !message.isEmpty {

                        Text(message)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    metadataSection(
                        item
                    )
                }

                if !item.isRead {

                    Circle()
                        .fill(AppColors.orange)
                        .frame(width: 9, height: 9)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(22)
        }
        .buttonStyle(.plain)
    }

    private func metadataSection(
        _ item: NotificationDTO
    ) -> some View {

        HStack(spacing: 8) {

            metadataBadge(
                title: "Origen",
                value: item.source
            )

            if let executionID = item.executionID {

                metadataBadge(
                    title: "Run",
                    value: "\(executionID)"
                )
            }

            if let draftID = item.draftID {

                metadataBadge(
                    title: "F8",
                    value: "\(draftID)"
                )
            }
        }
    }

    private func metadataBadge(
        title: String,
        value: String
    ) -> some View {

        HStack(spacing: 4) {

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(AppColors.secondaryText)

            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.primaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(10)
    }

    private func notificationIcon(
        _ item: NotificationDTO
    ) -> String {

        let type = item.notificationType.uppercased()

        if type.contains("FAILED") || item.severity.uppercased() == "ERROR" {
            return "exclamationmark.triangle.fill"
        }

        if type.contains("F8") {
            return "tablecells.fill"
        }

        if type.contains("REPORT") {
            return "doc.text.fill"
        }

        if type.contains("RISK") {
            return "bolt.fill"
        }

        if type.contains("COMPLETED") {
            return "checkmark.circle.fill"
        }

        return "bell.fill"
    }

    private func notificationColor(
        _ item: NotificationDTO
    ) -> Color {

        let severity = item.severity.uppercased()

        if severity == "ERROR" {
            return AppColors.red
        }

        if severity == "WARNING" {
            return AppColors.orange
        }

        if severity == "SUCCESS" {
            return AppColors.green
        }

        return AppColors.blue
    }

    private func notificationLabel(
        _ item: NotificationDTO
    ) -> String {

        let source = item.source.uppercased()

        if source == "PIPELINE" {
            return "Pipeline"
        }

        if source == "REPORTS" {
            return "Reporte"
        }

        if source == "F8" {
            return "F8"
        }

        if source == "ALERTS" {
            return "Alerta"
        }

        return source
    }
}