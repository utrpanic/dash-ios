public struct BusRoute: Equatable, Hashable, Identifiable, Sendable {
  public let id: Int
  public let number: String

  public init(id: Int, number: String) {
    self.id = id
    self.number = number
  }
}

public extension BusRoute {
  static let gyeonggi_9 = BusRoute(id: 200000103, number: "9")
  static let gyeonggi_9_1 = BusRoute(id: 200000186, number: "9-1")
  static let gyeonggi_13 = BusRoute(id: 200000037, number: "13")
  static let gyeonggi_13_1 = BusRoute(id: 200000069, number: "13-1")
  static let gyeonggi_13_4 = BusRoute(id: 200000185, number: "13-4")
  static let gyeonggi_13_5 = BusRoute(id: 200000090, number: "13-5")
  static let gyeonggi_15_1 = BusRoute(id: 200000152, number: "15-1")
  static let seoul_662 = BusRoute(id: 100100550, number: "662")
}
