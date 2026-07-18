public struct BusRouteStation: Equatable, Hashable, Identifiable, Sendable {
  public var id: Int { busStop.id }

  public let busStop: BusStop
  public let sequence: Int
  public let isTurnPoint: Bool

  public var x: Double { busStop.longitude }
  public var y: Double { busStop.latitude }

  public init(
    busStop: BusStop,
    sequence: Int,
    isTurnPoint: Bool
  ) {
    self.busStop = busStop
    self.sequence = sequence
    self.isTurnPoint = isTurnPoint
  }
}
