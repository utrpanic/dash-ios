public struct BusStop: Equatable, Hashable, Identifiable, Sendable {
  public let id: Int
  public let name: String
  public let alias: String?

  public init(id: Int, name: String, alias: String? = nil) {
    self.id = id
    self.name = name
    self.alias = alias
  }
}

public extension BusStop {
  static let suwonStationExit7Inner = BusStop(
    id: 202000106,
    name: "수원역7번출구.AK플라자",
    alias: "Inner Platform"
  )
  static let suwonStationExit7Outer = BusStop(
    id: 202000219,
    name: "수원역7번출구.AK플라자",
    alias: "Outer Platform"
  )
  static let homaesilSsangyongApartment = BusStop(
    id: 201000096,
    name: "호매실쌍용아파트",
    alias: "02028"
  )
}
