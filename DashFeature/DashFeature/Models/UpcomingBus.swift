import Foundation

public struct UpcomingBus: Equatable, Hashable, Identifiable, Sendable {
  public var id: String {
    "\(targetStop.id)-\(busStop.id)-\(busRoute.id)-\(timeIntervalUntilArrival)"
  }

  public let targetStop: TargetStop
  public let busStop: BusStop
  public let busRoute: BusRoute
  public let timeIntervalUntilArrival: TimeInterval

  public init(
    targetStop: TargetStop,
    busStop: BusStop,
    busRoute: BusRoute,
    timeIntervalUntilArrival: TimeInterval
  ) {
    self.targetStop = targetStop
    self.busStop = busStop
    self.busRoute = busRoute
    self.timeIntervalUntilArrival = timeIntervalUntilArrival
  }
}

extension Array where Element == UpcomingBus {
  var sortedByArrival: [UpcomingBus] {
    sorted { $0.timeIntervalUntilArrival < $1.timeIntervalUntilArrival }
  }
}
