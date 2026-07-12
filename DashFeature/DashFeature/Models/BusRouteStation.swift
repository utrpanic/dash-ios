public struct BusRouteStation: Equatable, Hashable, Identifiable, Sendable {
  public var id: Int { busStop.id }

  public let busStop: BusStop
  public let sequence: Int
  public let isTurnPoint: Bool
  public let x: Double
  public let y: Double

  public init(
    busStop: BusStop,
    sequence: Int,
    isTurnPoint: Bool,
    x: Double,
    y: Double
  ) {
    self.busStop = busStop
    self.sequence = sequence
    self.isTurnPoint = isTurnPoint
    self.x = x
    self.y = y
  }
}
