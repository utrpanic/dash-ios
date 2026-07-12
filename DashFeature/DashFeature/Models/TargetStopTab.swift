public struct TargetStopTab: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let targetStops: [TargetStop]
  public let busRoutes: [BusRoute]

  public init(id: String, title: String, targetStops: [TargetStop], busRoutes: [BusRoute]) {
    self.id = id
    self.title = title
    self.targetStops = targetStops
    self.busRoutes = busRoutes
  }
}
