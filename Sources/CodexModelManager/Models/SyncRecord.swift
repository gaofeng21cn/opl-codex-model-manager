import Foundation

struct SyncRecord: Identifiable, Hashable {
    let id: Int
    let recordedAt: Date?
    let status: String
    let appVersion: String
    let bundledCount: Int
    let customCount: Int
    let currentHash: String?
    let desiredHash: String?
    let backupPath: String?

    var totalCount: Int { bundledCount + customCount }
    var changed: Bool { status == "updated" }
    var hashesMatch: Bool {
        guard let currentHash, let desiredHash else { return changed }
        return currentHash == desiredHash
    }
}

struct SchedulerSnapshot: Hashable {
    var isLoaded = false
    var state = "unknown"
    var runs: Int?
    var lastExitCode: Int?
    var intervalSeconds: Int?
    var watchPaths: [String] = []
    var errorLogBytes: Int64 = 0

    var isHealthy: Bool {
        isLoaded && lastExitCode == 0 && errorLogBytes == 0
    }
}

struct CatalogSnapshot {
    var models: [CatalogModel]
    var records: [SyncRecord]
    var scheduler: SchedulerSnapshot
    var lastRunAt: Date?
    var lastRunIsExact: Bool

    static let empty = CatalogSnapshot(
        models: [],
        records: [],
        scheduler: SchedulerSnapshot(),
        lastRunAt: nil,
        lastRunIsExact: false
    )

    var officialModels: [CatalogModel] { models.filter { $0.source == .official } }
    var customModels: [CatalogModel] { models.filter { $0.source == .custom } }
    var latestRecord: SyncRecord? { records.first }
}
