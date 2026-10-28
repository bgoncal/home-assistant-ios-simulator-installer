import Darwin

enum LocalNetwork {
    static func ipv4Address() -> String? {
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0, let first = addresses else { return nil }
        defer { freeifaddrs(addresses) }

        for interface in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let entry = interface.pointee
            let flags = Int32(entry.ifa_flags)
            guard let address = entry.ifa_addr,
                  address.pointee.sa_family == sa_family_t(AF_INET),
                  flags & IFF_UP != 0, flags & IFF_RUNNING != 0, flags & IFF_LOOPBACK == 0,
                  String(validatingCString: entry.ifa_name)?.hasPrefix("en") == true else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(address, socklen_t(address.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else {
                continue
            }
            return host.withUnsafeBufferPointer { $0.baseAddress.flatMap(String.init(validatingCString:)) }
        }
        return nil
    }
}
