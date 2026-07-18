public struct TargetStop: Equatable, Hashable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let busStops: [BusStop]

  public var centerLatitude: Double {
    busStops.map(\.latitude).reduce(0, +) / Double(busStops.count)
  }

  public var centerLongitude: Double {
    busStops.map(\.longitude).reduce(0, +) / Double(busStops.count)
  }

  public init(id: String, name: String, busStops: [BusStop]) {
    precondition(!busStops.isEmpty, "TargetStop requires at least one bus stop.")
    self.id = id
    self.name = name
    self.busStops = busStops
  }
}

public extension TargetStop {
  static let suwonStation = TargetStop(
    id: "suwon-station",
    name: "수원역",
    busStops: [
      .suwonStationExit7Outer,
      .suwonStationExit7Inner,
    ]
  )
  static let homaesilSsangyongApartment = TargetStop(
    id: "homaesil-ssangyong-apartment",
    name: "호매실쌍용아파트",
    busStops: [
      .homaesilSsangyongApartment,
    ]
  )
}
