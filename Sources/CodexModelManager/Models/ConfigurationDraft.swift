import CodexModelCore
import Foundation

struct ConfigurationDraft: Equatable {
    var codexRuntimePath = ""
    var customSourcePath = ""
    var mergedCatalogPath = ""
    var syncLogPath = ""
    var errorLogPath = ""
    var launchAgentPlistPath = ""
    var launchAgentLabel = ""
    var backupDirectoryPath = ""

    init() {}

    init(configuration: AppConfiguration) {
        codexRuntimePath = configuration.codexRuntimePath ?? CodexRuntimeLocator.find()?.path ?? ""
        customSourcePath = configuration.customSourcePath
        mergedCatalogPath = configuration.mergedCatalogPath
        syncLogPath = configuration.syncLogPath
        errorLogPath = configuration.errorLogPath
        launchAgentPlistPath = configuration.launchAgentPlistPath
        launchAgentLabel = configuration.launchAgentLabel
        backupDirectoryPath = configuration.backupDirectoryPath
    }

    var configuration: AppConfiguration {
        AppConfiguration(
            codexRuntimePath: codexRuntimePath,
            customSourcePath: customSourcePath,
            mergedCatalogPath: mergedCatalogPath,
            syncLogPath: syncLogPath,
            errorLogPath: errorLogPath,
            launchAgentPlistPath: launchAgentPlistPath,
            launchAgentLabel: launchAgentLabel,
            backupDirectoryPath: backupDirectoryPath
        )
    }

    var isComplete: Bool {
        [
            codexRuntimePath,
            customSourcePath,
            mergedCatalogPath,
            syncLogPath,
            errorLogPath,
            launchAgentPlistPath,
            launchAgentLabel,
            backupDirectoryPath
        ].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
