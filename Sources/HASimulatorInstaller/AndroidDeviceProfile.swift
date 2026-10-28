import Foundation

struct AndroidDeviceProfile: Hashable, Identifiable {
    let id: String
    let name: String
    let isTablet: Bool

    static let all = [
        AndroidDeviceProfile(id: "pixel_10", name: "Pixel 10", isTablet: false),
        AndroidDeviceProfile(id: "pixel_10_pro", name: "Pixel 10 Pro", isTablet: false),
        AndroidDeviceProfile(id: "pixel_10_pro_xl", name: "Pixel 10 Pro XL", isTablet: false),
        AndroidDeviceProfile(id: "pixel_10_pro_fold", name: "Pixel 10 Pro Fold", isTablet: false),
        AndroidDeviceProfile(id: "pixel_9", name: "Pixel 9", isTablet: false),
        AndroidDeviceProfile(id: "pixel_9a", name: "Pixel 9a", isTablet: false),
        AndroidDeviceProfile(id: "pixel_8", name: "Pixel 8", isTablet: false),
        AndroidDeviceProfile(id: "pixel_7", name: "Pixel 7", isTablet: false),
        AndroidDeviceProfile(id: "pixel_fold", name: "Pixel Fold", isTablet: false),
        AndroidDeviceProfile(id: "small_phone", name: "Small Phone", isTablet: false),
        AndroidDeviceProfile(id: "medium_phone", name: "Medium Phone", isTablet: false),
        AndroidDeviceProfile(id: "pixel_tablet", name: "Pixel Tablet", isTablet: true),
        AndroidDeviceProfile(id: "medium_tablet", name: "Medium Tablet", isTablet: true),
    ]

    static let standard = all[4]
}
