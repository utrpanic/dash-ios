public struct BoardingPointTab: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let boardingPoints: [BoardingPoint]
  public let busRoutes: [BusRoute]

  public init(id: String, title: String, boardingPoints: [BoardingPoint], busRoutes: [BusRoute]) {
    self.id = id
    self.title = title
    self.boardingPoints = boardingPoints
    self.busRoutes = busRoutes
  }
}
