import Foundation

enum SidebarItem: Hashable {
    case run
    case setup
    case downloads
    case recent(UUID)
}
