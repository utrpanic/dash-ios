public struct TargetStop: Equatable, Hashable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let latitude: Double
  public let longitude: Double
  public let busStops: [BusStop]

  public init(
    id: String,
    name: String,
    latitude: Double,
    longitude: Double,
    busStops: [BusStop]
  ) {
    self.id = id
    self.name = name
    self.latitude = latitude
    self.longitude = longitude
    self.busStops = busStops
  }
}

public extension TargetStop {
  static let suwonStation = TargetStop(
    id: "suwon-station",
    name: "수원역",
    latitude: 37.2674167,
    longitude: 127.0009,
    busStops: [
      .suwonStationExit7Outer,
      .suwonStationExit7Inner,
    ]
  )
  static let homaesilSsangyongApartment = TargetStop(
    id: "homaesil-ssangyong-apartment",
    name: "호매실쌍용아파트",
    latitude: 37.2678,
    longitude: 126.9513167,
    busStops: [
      .homaesilSsangyongApartment,
    ]
  )
}
