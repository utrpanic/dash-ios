public struct BusStop: Equatable, Hashable, Identifiable, Sendable {
  public let id: Int
  public let name: String
  public let alias: String?

  public init(id: Int, name: String, alias: String? = nil) {
    self.id = id
    self.name = name
    self.alias = alias
  }
}
