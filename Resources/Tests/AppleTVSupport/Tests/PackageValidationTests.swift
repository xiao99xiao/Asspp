import ApplePackage
import Foundation
import Testing
import ZIPFoundation

struct PackageValidationTests {
    @Test(arguments: ["AppleTVOS", "iPhoneOS"])
    func appleTVDownloadsRequireTVOSPackage(platform: String) throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension("ipa")
        defer { try? FileManager.default.removeItem(at: url) }
        let plist = try PropertyListSerialization.data(
            fromPropertyList: ["CFBundleSupportedPlatforms": [platform]], format: .binary, options: 0
        )
        let archive = try Archive(url: url, accessMode: .create)
        try archive.addEntry(
            with: "Payload/Example.app/Info.plist", type: .file, uncompressedSize: Int64(plist.count)
        ) { position, size in
            plist.subdata(in: Int(position) ..< Int(position) + size)
        }
        if platform == "AppleTVOS" {
            try PackagePlatformValidator.ensurePackage(at: url, supports: .appleTV)
        } else {
            #expect(throws: (any Error).self) {
                try PackagePlatformValidator.ensurePackage(at: url, supports: .appleTV)
            }
        }
    }
}
