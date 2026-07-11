public struct TargetStop: Equatable, Hashable, Identifiable, Sendable {
  public var id: String {
    "\(busStop.id)-\(busRoute.id)"
  }

  public let busStop: BusStop
  public let busRoute: BusRoute

  public init(busStop: BusStop, busRoute: BusRoute) {
    self.busStop = busStop
    self.busRoute = busRoute
  }
}
