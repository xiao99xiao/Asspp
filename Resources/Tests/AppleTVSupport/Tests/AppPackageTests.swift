import ApplePackage
import Foundation
@testable import PackageModel
import Testing

struct AppPackageTests {
    private func software() -> Software {
        Software(
            id: 42, bundleID: "example.universal", name: "Universal App", version: "1.0",
            artistName: "Developer", sellerName: "Developer", description: "",
            averageUserRating: 0, userRatingCount: 0, artworkUrl: "", screenshotUrls: [],
            minimumOsVersion: "17.0", releaseDate: "2026-01-01T00:00:00Z", primaryGenreName: "Utilities"
        )
    }

    @Test func platformsHaveDistinctIdentity() {
        let packages = EntityType.allCases.map { AppStore.AppPackage(software: software(), entityType: $0) }
        #expect(Set(packages).count == EntityType.allCases.count)
        #expect(Set(packages.map(\.id)).count == EntityType.allCases.count)
    }

    @Test(arguments: EntityType.allCases)
    func roundTripPreservesPlatformAndVersion(entityType: EntityType) throws {
        var package = AppStore.AppPackage(software: software(), entityType: entityType)
        package.externalVersionID = "123456"
        package.downloadOutput = DownloadOutput(
            downloadURL: "https://example.com/app.ipa", sinfs: [], bundleShortVersionString: "1.0",
            bundleVersion: "10", iTunesMetadata: Data([1, 2, 3])
        )
        let decoded = try JSONDecoder().decode(AppStore.AppPackage.self, from: JSONEncoder().encode(package))
        #expect(decoded.entityType == entityType)
        #expect(decoded.id == package.id)
        #expect(decoded.releaseDate == package.releaseDate)
        #expect(decoded.externalVersionID == package.externalVersionID)
        #expect(decoded.downloadOutput == package.downloadOutput)
    }

    @Test func legacyDownloadStillDecodes() throws {
        let package = AppStore.AppPackage(software: software())
        let encoded = try JSONEncoder().encode(package)
        var legacy = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "entityType")
        let decoded = try JSONDecoder().decode(
            AppStore.AppPackage.self, from: JSONSerialization.data(withJSONObject: legacy)
        )
        #expect(decoded.entityType == .iPhone)
        #expect(decoded.software == package.software)
        #expect(decoded.releaseDate == package.releaseDate)
    }

    @Test(arguments: EntityType.allCases)
    func historicalVersionIsUsedWithoutLookingUpLatest(entityType: EntityType) async throws {
        var package = AppStore.AppPackage(software: software(), entityType: entityType)
        package.externalVersionID = "7654321"
        // An invalid region proves an explicit historical version needs no lookup.
        let versionID = try await package.resolveExternalVersionID(countryCode: "invalid")
        #expect(versionID == "7654321")
    }
}

struct LivePlatformLookupTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["ASSPP_LIVE_STORE_TESTS"] == "1"))
    func latestVersionsUseDifferentPlatformLines() async throws {
        let software = Software(
            id: 1136220934, bundleID: "com.firecore.infuse", name: "Infuse", version: "",
            artistName: "", sellerName: "", description: "", averageUserRating: 0,
            userRatingCount: 0, artworkUrl: "", screenshotUrls: [], minimumOsVersion: "",
            releaseDate: "", primaryGenreName: ""
        )
        let ios = try await AppStore.AppPackage(software: software, entityType: .iPhone)
            .resolveExternalVersionID(countryCode: "US")
        let tvos = try await AppStore.AppPackage(software: software, entityType: .appleTV)
            .resolveExternalVersionID(countryCode: "US")
        #expect(!ios.isEmpty)
        #expect(!tvos.isEmpty)
        #expect(ios != tvos)
    }
}
