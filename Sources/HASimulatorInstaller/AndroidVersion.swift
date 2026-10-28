import Foundation

struct AndroidVersion: Hashable, Identifiable {
    let apiLevel: Int
    let name: String

    var id: Int { apiLevel }

    var systemImage: String {
        #if arch(arm64)
        let abi = "arm64-v8a"
        #else
        let abi = "x86_64"
        #endif
        return "system-images;android-\(apiLevel);google_apis_playstore;\(abi)"
    }

    static let all = [
        AndroidVersion(apiLevel: 37, name: "Android 17"),
        AndroidVersion(apiLevel: 36, name: "Android 16"),
        AndroidVersion(apiLevel: 35, name: "Android 15"),
        AndroidVersion(apiLevel: 34, name: "Android 14"),
        AndroidVersion(apiLevel: 33, name: "Android 13"),
        AndroidVersion(apiLevel: 32, name: "Android 12L"),
        AndroidVersion(apiLevel: 31, name: "Android 12"),
        AndroidVersion(apiLevel: 30, name: "Android 11"),
        AndroidVersion(apiLevel: 29, name: "Android 10"),
        AndroidVersion(apiLevel: 28, name: "Android 9"),
    ]

    static let standard = all.first { $0.apiLevel == Constants.androidSystemImageAPI }!
}
