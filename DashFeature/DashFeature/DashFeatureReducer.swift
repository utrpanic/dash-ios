import ComposableArchitecture

@Reducer
public struct DashFeature {
  public init() {}

  @Dependency(\.busRouteAPIClient) var busRouteAPIClient

  @ObservableState
  public struct State: Equatable {
    public var tabs: [TargetStopTab]
    public var selectedTabID: TargetStopTab.ID
    public var upcomingBuses: [UpcomingBus]
    public var busRouteSearchKeyword: String
    public var busRouteSearchResults: [BusRoute]
    public var isSearchingBusRoutes: Bool
    public var busRouteSearchErrorMessage: String?

    public init() {
      self.tabs = .mock
      self.selectedTabID = "suwon-station"
      self.upcomingBuses = .mock
      self.busRouteSearchKeyword = ""
      self.busRouteSearchResults = []
      self.isSearchingBusRoutes = false
      self.busRouteSearchErrorMessage = nil
    }
  }

  public enum Action: Equatable {
    case addButtonTapped
    case busRouteSearchRequested(keyword: String)
    case busRouteSearchResponse(BusRouteSearchResponse)
    case tabSelected(TargetStopTab.ID)
  }

  public enum BusRouteSearchResponse: Equatable {
    case success([BusRoute])
    case failure(String)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        return .none

      case let .busRouteSearchRequested(keyword):
        state.busRouteSearchKeyword = keyword
        state.isSearchingBusRoutes = true
        state.busRouteSearchErrorMessage = nil
        let searchRoutes = busRouteAPIClient.searchRoutes
        return .run { send in
          do {
            let routes = try await searchRoutes(keyword)
            await send(.busRouteSearchResponse(.success(routes)))
          } catch {
            await send(.busRouteSearchResponse(.failure(String(describing: error))))
          }
        }

      case let .busRouteSearchResponse(.success(routes)):
        state.isSearchingBusRoutes = false
        state.busRouteSearchResults = routes
        state.busRouteSearchErrorMessage = nil
        return .none

      case let .busRouteSearchResponse(.failure(message)):
        state.isSearchingBusRoutes = false
        state.busRouteSearchErrorMessage = message
        return .none

      case let .tabSelected(tabID):
        state.selectedTabID = tabID
        return .none
      }
    }
  }
}
