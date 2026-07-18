public struct BoardingPoint: Equatable, Hashable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let stops: [BusStop]

  public var centerLatitude: Double {
    stops.map(\.latitude).reduce(0, +) / Double(stops.count)
  }

  public var centerLongitude: Double {
    stops.map(\.longitude).reduce(0, +) / Double(stops.count)
  }

  public init(id: String, name: String, stops: [BusStop]) {
    precondition(!stops.isEmpty, "BoardingPoint requires at least one bus stop.")
    self.id = id
    self.name = name
    self.stops = stops
  }
}

public extension BoardingPoint {
  static let suwonStation = BoardingPoint(
    id: "suwon-station",
    name: "수원역",
    stops: [
      .suwonStationExit7Outer,
      .suwonStationExit7Inner,
    ]
  )
  static let homaesilSsangyongApartment = BoardingPoint(
    id: "homaesil-ssangyong-apartment",
    name: "호매실쌍용아파트",
    stops: [
      .homaesilSsangyongApartment,
    ]
  )
}
