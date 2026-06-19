import SwiftUI

struct BranchModel: Identifiable {

    let id = UUID()

    let name: String
    let subtitle: String

    let health: Int

    let breakRisk: Int
    let noRotation: Int
    let overstock: Int

    let color: Color
}

extension BranchModel {

    init(dto: BranchDTO) {

        let color: Color

        if dto.health >= 80 {

            color = AppColors.green

        } else if dto.health >= 60 {

            color = AppColors.orange

        } else {

            color = AppColors.red
        }

        self.init(

            name: dto.branch,

            subtitle: "\(dto.totalCases) casos",

            health: dto.health,

            breakRisk: dto.critical,

            noRotation: dto.high,

            overstock: dto.medium,

            color: color
        )
    }
}