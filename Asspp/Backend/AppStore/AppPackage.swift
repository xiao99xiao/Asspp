//
//  AppPackage.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Foundation

extension AppStore {
    struct AppPackage: Codable, Identifiable, Hashable {
        var id: String {
            "\(software.bundleID):\(entityType.rawValue)"
        }

        var software: ApplePackage.Software
        var entityType: ApplePackage.EntityType
        var releaseDate: Date?
        var downloadOutput: ApplePackage.DownloadOutput?
        var externalVersionID: String?

        init(software: ApplePackage.Software, entityType: ApplePackage.EntityType = .iPhone) {
            self.software = software
            self.entityType = entityType
            releaseDate = ISO8601DateFormatter().date(from: software.releaseDate)
        }

        // Treat legacy records without a platform as iPhone downloads.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            software = try container.decode(ApplePackage.Software.self, forKey: .software)
            entityType = try container.decodeIfPresent(ApplePackage.EntityType.self, forKey: .entityType) ?? .iPhone
            releaseDate = try container.decodeIfPresent(Date.self, forKey: .releaseDate)
            downloadOutput = try container.decodeIfPresent(ApplePackage.DownloadOutput.self, forKey: .downloadOutput)
            externalVersionID = try container.decodeIfPresent(String.self, forKey: .externalVersionID)
        }

        private enum CodingKeys: String, CodingKey {
            case software, entityType, releaseDate, downloadOutput, externalVersionID
        }

        func resolveExternalVersionID(countryCode: String) async throws -> String {
            if let externalVersionID, !externalVersionID.isEmpty {
                return externalVersionID
            }
            let metadata = try await ApplePackage.PlatformVersionLookup.lookup(
                appID: software.id,
                countryCode: countryCode,
                entityType: entityType,
            )
            return metadata.externalVersionID
        }

        static func == (lhs: AppPackage, rhs: AppPackage) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
