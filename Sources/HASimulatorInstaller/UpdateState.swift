import Foundation

enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate
    case available(AppUpdate)
    case installing(AppUpdate)
    case failed(String, AppUpdate?)
}
