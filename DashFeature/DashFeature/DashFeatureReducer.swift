import ComposableArchitecture
import Foundation

@Reducer
public struct DashFeature {
  public init() {}

  @Dependency(\.busArrivalAPIClient) var busArrivalAPIClient
  @Dependency(\.busRouteAPIClient) var busRouteAPIClient
  @Dependency(\.userLocationClient) var userLocationClient

  public enum TargetStopSelection: Equatable, Hashable {
    case locating
    case locationPermissionDenied
    case locationUnavailable
    case selected(TargetStopTab.ID)
  }

  @ObservableState
  public struct State: Equatable {
    public var tabs: [TargetStopTab]
    public var targetStopSelection: TargetStopSelection
    public var hasRequestedInitialLocation: Bool
    public var upcomingBuses: [UpcomingBus]
    public var isLoadingUpcomingBuses: Bool
    public var upcomingBusesErrorMessage: String?
    public var busRouteSearchKeyword: String
    public var busRouteSearchResults: [BusRoute]
    public var isSearchingBusRoutes: Bool
    public var busRouteSearchErrorMessage: String?

    public init() {
      self.tabs = .mock
      self.targetStopSelection = .locating
      self.hasRequestedInitialLocation = false
      self.upcomingBuses = []
      self.isLoadingUpcomingBuses = false
      self.upcomingBusesErrorMessage = nil
      self.busRouteSearchKeyword = ""
      self.busRouteSearchResults = []
      self.isSearchingBusRoutes = false
      self.busRouteSearchErrorMessage = nil
    }

    public var selectedTabID: TargetStopTab.ID? {
      guard case let .selected(tabID) = targetStopSelection else {
        return nil
      }
      return tabID
    }
  }

  public enum Action: Equatable {
    case editButtonTapped
    case busRouteSearchRequested(keyword: String)
    case busRouteSearchResponse(BusRouteSearchResponse)
    case loadUpcomingBuses
    case loadUpcomingBusesResponse(UpcomingBusesResponse)
    case nextTargetStopButtonTapped
    case refreshButtonTapped
    case tabSelected(TargetStopTab.ID)
    case task
    case userLocationResponse(UserLocationResponse)
  }

  public enum UserLocationResponse: Equatable {
    case success(UserLocation)
    case authorizationDenied
    case unavailable
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
      case .editButtonTapped:
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
        guard let selectedTabID = state.selectedTabID,
              let tab = state.tabs.first(where: { $0.id == selectedTabID })
        else {
          state.isLoadingUpcomingBuses = false
          return .none
        }

        state.isLoadingUpcomingBuses = true
        state.upcomingBusesErrorMessage = nil
        let fetchArrivals = busArrivalAPIClient.fetchArrivals

        return .run { send in
          do {
            let upcomingBuses = try await Self.fetchUpcomingBuses(
              targetStops: tab.targetStops,
              busRoutes: tab.busRoutes,
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

      case .nextTargetStopButtonTapped:
        guard !state.tabs.isEmpty else {
          return .none
        }

        let selectedIndex = state.selectedTabID
          .flatMap { selectedTabID in
            state.tabs.firstIndex { $0.id == selectedTabID }
          } ?? -1
        let nextIndex = state.tabs.index(after: selectedIndex) % state.tabs.count
        state.targetStopSelection = .selected(state.tabs[nextIndex].id)
        return .send(.loadUpcomingBuses)

      case .refreshButtonTapped:
        return .send(.loadUpcomingBuses)

      case let .tabSelected(tabID):
        state.targetStopSelection = .selected(tabID)
        return .send(.loadUpcomingBuses)

      case .task:
        guard !state.hasRequestedInitialLocation else {
          return .none
        }

        state.hasRequestedInitialLocation = true
        state.isLoadingUpcomingBuses = true
        let requestLocation = userLocationClient.requestLocation
        return .run { send in
          do {
            await send(.userLocationResponse(.success(try await requestLocation())))
          } catch UserLocationError.authorizationDenied {
            await send(.userLocationResponse(.authorizationDenied))
          } catch {
            await send(.userLocationResponse(.unavailable))
          }
        }

      case let .userLocationResponse(.success(location)):
        guard let nearestTabID = Self.nearestTabID(to: location, in: state.tabs) else {
          state.targetStopSelection = .locationUnavailable
          state.isLoadingUpcomingBuses = false
          return .none
        }
        state.targetStopSelection = .selected(nearestTabID)
        return .send(.loadUpcomingBuses)

      case .userLocationResponse(.authorizationDenied):
        state.targetStopSelection = .locationPermissionDenied
        state.isLoadingUpcomingBuses = false
        return .none

      case .userLocationResponse(.unavailable):
        state.targetStopSelection = .locationUnavailable
        state.isLoadingUpcomingBuses = false
        return .none
      }
    }
  }
}

private extension DashFeature {
  static func nearestTabID(
    to location: UserLocation,
    in tabs: [TargetStopTab]
  ) -> TargetStopTab.ID? {
    tabs.compactMap { tab -> (id: TargetStopTab.ID, distance: Double)? in
      guard let distance = tab.targetStops
        .map({ distance(from: location, to: $0) })
        .min()
      else {
        return nil
      }
      return (tab.id, distance)
    }
    .min { $0.distance < $1.distance }?
    .id
  }

  static func distance(from location: UserLocation, to targetStop: TargetStop) -> Double {
    let earthRadius = 6_371_000.0
    let latitudeDelta = radians(targetStop.latitude - location.latitude)
    let longitudeDelta = radians(targetStop.longitude - location.longitude)
    let sourceLatitude = radians(location.latitude)
    let destinationLatitude = radians(targetStop.latitude)
    let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
      + cos(sourceLatitude) * cos(destinationLatitude)
      * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
    return earthRadius * 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
  }

  static func radians(_ degrees: Double) -> Double {
    degrees * .pi / 180
  }

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
