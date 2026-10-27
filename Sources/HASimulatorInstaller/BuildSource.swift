import Foundation

enum BuildSource: Hashable, Sendable {
    case latest
    case pullRequest(Int)

    static func pullRequestNumber(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = trimmed.range(of: "/pull/") {
            let digits = trimmed[range.upperBound...].prefix(while: \.isNumber)
            return Int(digits)
        }
        return Int(trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
    }
}
