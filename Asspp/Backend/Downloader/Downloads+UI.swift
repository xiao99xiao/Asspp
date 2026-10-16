//
//  Downloads+UI.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import ApplePackage
import Foundation
import SwiftUI

enum DownloadAction: Hashable {
    case suspend
    case resume
    case restart
    case delete
}

@MainActor
extension Downloads {
    func performDownloadAction(for request: PackageManifest, action: DownloadAction) {
        switch action {
        case .suspend:
            suspend(request: request)
        case .resume:
            resume(request: request)
        case .restart:
            restart(request: request)
        case .delete:
            delete(request: request)
        }
    }

    func getAvailableActions(for request: PackageManifest) -> [DownloadAction] {
        switch request.state.status {
        case .pending, .downloading:
            [.suspend, .delete]
        case .paused:
            [.resume, .delete]
        case .failed:
            [.restart, .delete]
        case .completed:
            [.delete]
        }
    }

    func getActionLabel(for action: DownloadAction) -> (title: String, systemImage: String, isDestructive: Bool) {
        switch action {
        case .suspend:
            (String(localized: "Pause"), "stop.fill", false)
        case .resume:
            (String(localized: "Resume"), "play.fill", false)
        case .restart:
            (String(localized: "Restart Download"), "arrow.clockwise", false)
        case .delete:
            (String(localized: "Delete"), "trash", true)
        }
    }
}

extension Downloads {
    func startDownload(for package: AppStore.AppPackage, accountID: String) async throws {
        try await AppStore.this.withAccount(id: accountID) { account in
            // Both download endpoints need an explicit version to select the
            // correct platform for apps sharing an App Store ID across iOS/tvOS.
            guard let countryCode = ApplePackage.Configuration.countryCode(for: account.account.store) else {
                throw NSError(
                    domain: "Asspp.Download",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: String(localized: "Unsupported App Store region.")],
                )
            }
            let versionID = try await package.resolveExternalVersionID(countryCode: countryCode)
            let downloadOutput = try await ApplePackage.Download.download(
                account: &account.account,
                app: package.software,
                externalVersionID: versionID,
            )
            var downloadedPackage = package
            downloadedPackage.software.version = downloadOutput.bundleShortVersionString
            let request = try Downloads.this.add(request: .init(
                account: account,
                package: downloadedPackage,
                downloadOutput: downloadOutput,
            ))
            Downloads.this.resume(request: request)
        }
    }
}
