import Foundation

struct Activity: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var detail: String?
    var progress: Double?
}
