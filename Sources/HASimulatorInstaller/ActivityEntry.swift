import Foundation

struct ActivityEntry: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let component: Component
    let message: String
    let isError: Bool
}
