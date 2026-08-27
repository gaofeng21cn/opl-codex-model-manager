import AppKit
import Foundation

@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var snapshot = CatalogSnapshot.empty
    @Published private(set) var isRefreshing = false
    @Published private(set) var isSyncing = false
    @Published private(set) var isAddingModel = false
    @Published var errorMessage: String?
    @Published var isPresentingAddModel = false

    @Published private(set) var paths: CatalogPaths?
    let configurationURL: URL
    private var service: CatalogDataService?
    private var configurationErrorMessage: String?

    var isConfigured: Bool { service != nil }

    init(configurationURL: URL = AppConfiguration.defaultURL) {
        self.configurationURL = configurationURL
        do {
            let paths = try AppConfiguration.load(from: configurationURL)
            self.paths = paths
            self.service = CatalogDataService(paths: paths)
            self.configurationErrorMessage = nil
        } catch {
            self.paths = nil
            self.service = nil
            self.configurationErrorMessage = error.localizedDescription
        }
    }

    init(service: CatalogDataService, configurationURL: URL = AppConfiguration.defaultURL) {
        self.configurationURL = configurationURL
        self.paths = service.paths
        self.service = service
        self.configurationErrorMessage = nil
    }

    func refresh() async {
        guard !isRefreshing else { return }
        guard let service else {
            errorMessage = configurationErrorMessage
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let service = service
            snapshot = try await Task.detached(priority: .userInitiated) {
                try service.loadSnapshot()
            }.value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func syncNow() async {
        guard !isSyncing else { return }
        guard let service else {
            errorMessage = configurationErrorMessage
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let service = service
            try await Task.detached(priority: .userInitiated) {
                try service.runSync()
            }.value
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
            await refresh()
        }
    }

    func addModel(_ draft: NewModelDraft) async -> Bool {
        guard !isAddingModel else { return false }
        guard let service else {
            errorMessage = configurationErrorMessage
            return false
        }
        isAddingModel = true
        defer { isAddingModel = false }
        do {
            let service = service
            try await Task.detached(priority: .userInitiated) {
                try service.addCustomModel(draft)
                try service.runSync()
            }.value
            await refresh()
            return true
        } catch {
            errorMessage = error.localizedDescription
            await refresh()
            return false
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
