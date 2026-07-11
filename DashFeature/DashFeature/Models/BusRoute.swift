public struct BusRoute: Equatable, Hashable, Identifiable, Sendable {
  public let id: Int
  public let number: String

  public init(id: Int, number: String) {
    self.id = id
    self.number = number
  }
}
