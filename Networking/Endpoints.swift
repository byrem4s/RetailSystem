import Foundation


enum Endpoints {

    static let baseURL = Environment.baseURL

    static let health = "\(baseURL)/system/health"

    static let warnings = "\(baseURL)/system/warnings"

    static let exportsHistory =  "\(baseURL)/exports/history"

    static let pipelineHistory = "\(baseURL)/pipeline/history"

    static let runPipeline =  "/pipeline/run"

    static let activity = "/activity"

    static let alerts = "/alerts"

    static let home = "/home"

    static let branches = "/branches"
}
