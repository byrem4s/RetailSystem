import SwiftUI

struct ResponsiveScrollView<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .frame(
                    maxWidth: AppSpacing.maxContentWidth,
                    alignment: .leading
                )
                .padding(.horizontal, horizontalPadding)
                .padding(.top, AppSpacing.regular)
                .padding(.bottom, AppSpacing.section)
                .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.background.ignoresSafeArea())
    }

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular
            ? AppSpacing.xLarge
            : AppSpacing.regular
    }
}

struct AppCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    init(
        padding: CGFloat = AppSpacing.regular,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
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
}

struct PageHeading: View {
    let eyebrow: String?
    let title: String
    let subtitle: String

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(AppColors.blue)
            }
            Text(title)
                .font(AppTypography.pageTitle)
                .foregroundStyle(AppColors.primaryText)
                .minimumScaleFactor(0.85)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct IconBadge: View {
    let systemName: String
    var color: Color = AppColors.blue
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12))
            .clipShape(
                RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
            )
    }
}

struct StatusPill: View {
    let title: String
    var color: Color = AppColors.blue

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.regular)
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .background(
                configuration.isPressed
                    ? AppColors.blue.opacity(0.78)
                    : AppColors.blue
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppSpacing.controlRadius,
                    style: .continuous
                )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColors.blue)
            .padding(.horizontal, AppSpacing.regular)
            .frame(minHeight: 46)
            .frame(maxWidth: .infinity)
            .background(AppColors.blue.opacity(configuration.isPressed ? 0.18 : 0.10))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppSpacing.controlRadius,
                    style: .continuous
                )
            )
    }
}

extension View {
    func appTextField() -> some View {
        padding(.horizontal, AppSpacing.regular)
            .frame(minHeight: 50)
            .background(AppColors.field)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppSpacing.controlRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppSpacing.controlRadius,
                    style: .continuous
                )
                .stroke(AppColors.border, lineWidth: 1)
            }
    }
}
