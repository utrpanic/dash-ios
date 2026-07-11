import Foundation

public struct UpcomingBus: Equatable, Hashable, Identifiable, Sendable {
  public var id: String {
    "\(target.id)-\(arrivalDate.timeIntervalSince1970)"
  }

  public let target: TargetStop
  public let arrivalDate: Date

  public init(target: TargetStop, arrivalDate: Date) {
    self.target = target
    self.arrivalDate = arrivalDate
  }
}

extension Array where Element == UpcomingBus {
  var sortedByArrival: [UpcomingBus] {
    sorted { $0.arrivalDate < $1.arrivalDate }
  }
}
