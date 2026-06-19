import Foundation


enum Endpoints {

    static let baseURL =
    "http://10.0.0.87:8080"

    static let health =
    "\(baseURL)/system/health"

    static let warnings =
    "\(baseURL)/system/warnings"

    static let exportsHistory =
    "\(baseURL)/exports/history"

    static let pipelineHistory =
    "\(baseURL)/pipeline/history"

    static let runPipeline = 
    "/pipeline/run"

    static let activity =
    "/activity"

    static let alerts =
    "/alerts"

    static let home =
    "/system/health"

    static let branches =
    "/branches"
}