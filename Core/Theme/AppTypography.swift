import SwiftUI

enum AppTypography {
    static let pageTitle = Font.system(
        .largeTitle,
        design: .rounded,
        weight: .bold
    )
    static let sectionTitle = Font.system(
        .title3,
        design: .rounded,
        weight: .bold
    )
    static let cardTitle = Font.system(
        .headline,
        design: .rounded,
        weight: .semibold
    )
    static let metric = Font.system(
        .title,
        design: .rounded,
        weight: .bold
    )
}
