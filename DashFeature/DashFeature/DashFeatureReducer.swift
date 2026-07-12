import ComposableArchitecture

@Reducer
public struct DashFeature {
  public init() {}

  @Dependency(\.busArrivalAPIClient) var busArrivalAPIClient
  @Dependency(\.busRouteAPIClient) var busRouteAPIClient

  @ObservableState
  public struct State: Equatable {
    public var tabs: [TargetStopTab]
    public var selectedTabID: TargetStopTab.ID
    public var upcomingBuses: [UpcomingBus]
    public var isLoadingUpcomingBuses: Bool
    public var upcomingBusesErrorMessage: String?
    public var busRouteSearchKeyword: String
    public var busRouteSearchResults: [BusRoute]
    public var isSearchingBusRoutes: Bool
    public var busRouteSearchErrorMessage: String?

    public init() {
      self.tabs = .mock
      self.selectedTabID = "suwon-station"
      self.upcomingBuses = []
      self.isLoadingUpcomingBuses = false
      self.upcomingBusesErrorMessage = nil
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
    case loadUpcomingBuses
    case loadUpcomingBusesResponse(UpcomingBusesResponse)
    case tabSelected(TargetStopTab.ID)
  }

  public enum BusRouteSearchResponse: Equatable {
    case success([BusRoute])
    case failure(String)
  }

  public enum UpcomingBusesResponse: Equatable {
    case success([UpcomingBus])
    case failure(String)
  }

  private enum CancelID: Hashable {
    case loadUpcomingBuses
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

      case .loadUpcomingBuses:
        state.isLoadingUpcomingBuses = true
        state.upcomingBusesErrorMessage = nil
        let tab = state.tabs.first { $0.id == state.selectedTabID }
        let fetchArrivals = busArrivalAPIClient.fetchArrivals

        return .run { send in
          do {
            let upcomingBuses = try await Self.fetchUpcomingBuses(
              targetStops: tab?.targetStops ?? [],
              busRoutes: tab?.busRoutes ?? [],
              fetchArrivals: fetchArrivals
            )
            await send(.loadUpcomingBusesResponse(.success(upcomingBuses)))
          } catch {
            await send(.loadUpcomingBusesResponse(.failure(String(describing: error))))
          }
        }
        .cancellable(id: CancelID.loadUpcomingBuses, cancelInFlight: true)

      case let .loadUpcomingBusesResponse(.success(upcomingBuses)):
        state.isLoadingUpcomingBuses = false
        state.upcomingBuses = upcomingBuses
        state.upcomingBusesErrorMessage = nil
        return .none

      case let .loadUpcomingBusesResponse(.failure(message)):
        state.isLoadingUpcomingBuses = false
        state.upcomingBusesErrorMessage = message
        return .none

      case let .tabSelected(tabID):
        state.selectedTabID = tabID
        return .send(.loadUpcomingBuses)
      }
    }
  }
}

private extension DashFeature {
  static func fetchUpcomingBuses(
    targetStops: [TargetStop],
    busRoutes: [BusRoute],
    fetchArrivals: @escaping @Sendable (_ stationId: Int) async throws -> [BusArrival]
  ) async throws -> [UpcomingBus] {
    var upcomingBuses: [UpcomingBus] = []
    let busRouteIDs = Set(busRoutes.map(\.id))

    for targetStop in targetStops {
      for busStop in targetStop.busStops {
        let arrivals = try await fetchArrivals(busStop.id)
        let matchingArrivals = arrivals.filter { busRouteIDs.contains($0.route.id) }
        for arrival in matchingArrivals {
          upcomingBuses.append(
            contentsOf: arrival.upcomingBuses(targetStop: targetStop, busStop: busStop)
          )
        }
      }
    }

    return upcomingBuses.sortedByArrival
  }
}
