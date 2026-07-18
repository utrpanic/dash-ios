import ComposableArchitecture
import Foundation

@Reducer
public struct DashFeature {
  public init() {}

  @Dependency(\.busArrivalAPIClient) var busArrivalAPIClient
  @Dependency(\.busRouteAPIClient) var busRouteAPIClient
  @Dependency(\.date.now) var now
  @Dependency(\.userLocationClient) var userLocationClient

  public enum BoardingPointSelection: Equatable, Hashable {
    case locating
    case locationPermissionDenied
    case locationUnavailable
    case selected(BoardingPoint.ID)
  }

  @ObservableState
  public struct State: Equatable {
    public var boardingPoints: [BoardingPoint]
    public var boardingPointSelection: BoardingPointSelection
    public var hasRequestedInitialLocation: Bool
    public var isRequestingUserLocation: Bool
    public var upcomingBuses: [UpcomingBus]
    public var isLoadingUpcomingBuses: Bool
    public var upcomingBusesErrorMessage: String?
    public var lastUpdatedAt: Date?
    public var busRouteSearchKeyword: String
    public var busRouteSearchResults: [BusRoute]
    public var isSearchingBusRoutes: Bool
    public var busRouteSearchErrorMessage: String?

    public init() {
      self.boardingPoints = .mock
      self.boardingPointSelection = .locating
      self.hasRequestedInitialLocation = false
      self.isRequestingUserLocation = false
      self.upcomingBuses = []
      self.isLoadingUpcomingBuses = false
      self.upcomingBusesErrorMessage = nil
      self.lastUpdatedAt = nil
      self.busRouteSearchKeyword = ""
      self.busRouteSearchResults = []
      self.isSearchingBusRoutes = false
      self.busRouteSearchErrorMessage = nil
    }

    public var selectedBoardingPointID: BoardingPoint.ID? {
      guard case let .selected(boardingPointID) = boardingPointSelection else {
        return nil
      }
      return boardingPointID
    }
  }

  public enum Action: Equatable {
    case editButtonTapped
    case busRouteSearchRequested(keyword: String)
    case busRouteSearchResponse(BusRouteSearchResponse)
    case loadUpcomingBuses
    case loadUpcomingBusesResponse(UpcomingBusesResponse)
    case locationButtonTapped
    case nextBoardingPointButtonTapped
    case refreshButtonTapped
    case boardingPointSelected(BoardingPoint.ID)
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
        guard let selectedBoardingPointID = state.selectedBoardingPointID,
              let boardingPoint = state.boardingPoints.first(
                where: { $0.id == selectedBoardingPointID }
              )
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
              boardingPoint: boardingPoint,
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
        state.lastUpdatedAt = now
        return .none

      case let .loadUpcomingBusesResponse(.failure(message)):
        state.isLoadingUpcomingBuses = false
        state.upcomingBusesErrorMessage = message
        return .none

      case .locationButtonTapped:
        state.isRequestingUserLocation = true
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

      case .nextBoardingPointButtonTapped:
        guard !state.boardingPoints.isEmpty else {
          return .none
        }

        let selectedIndex = state.selectedBoardingPointID
          .flatMap { selectedBoardingPointID in
            state.boardingPoints.firstIndex { $0.id == selectedBoardingPointID }
          } ?? -1
        let nextIndex = state.boardingPoints.index(after: selectedIndex)
          % state.boardingPoints.count
        state.boardingPointSelection = .selected(state.boardingPoints[nextIndex].id)
        state.lastUpdatedAt = nil
        return .send(.loadUpcomingBuses)

      case .refreshButtonTapped:
        return .send(.loadUpcomingBuses)

      case let .boardingPointSelected(boardingPointID):
        if boardingPointID != state.selectedBoardingPointID {
          state.lastUpdatedAt = nil
        }
        state.boardingPointSelection = .selected(boardingPointID)
        return .send(.loadUpcomingBuses)

      case .task:
        guard !state.hasRequestedInitialLocation else {
          return .none
        }

        state.hasRequestedInitialLocation = true
        state.isRequestingUserLocation = true
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
        state.isRequestingUserLocation = false
        guard let nearestBoardingPointID = Self.nearestBoardingPointID(
          to: location,
          in: state.boardingPoints
        ) else {
          state.boardingPointSelection = .locationUnavailable
          state.isLoadingUpcomingBuses = false
          return .none
        }
        if nearestBoardingPointID != state.selectedBoardingPointID {
          state.lastUpdatedAt = nil
        }
        state.boardingPointSelection = .selected(nearestBoardingPointID)
        return .send(.loadUpcomingBuses)

      case .userLocationResponse(.authorizationDenied):
        state.isRequestingUserLocation = false
        if state.selectedBoardingPointID == nil {
          state.boardingPointSelection = .locationPermissionDenied
          state.isLoadingUpcomingBuses = false
        }
        return .none

      case .userLocationResponse(.unavailable):
        state.isRequestingUserLocation = false
        if state.selectedBoardingPointID == nil {
          state.boardingPointSelection = .locationUnavailable
          state.isLoadingUpcomingBuses = false
        }
        return .none
      }
    }
  }
}

private extension DashFeature {
  static func nearestBoardingPointID(
    to location: UserLocation,
    in boardingPoints: [BoardingPoint]
  ) -> BoardingPoint.ID? {
    boardingPoints.map { boardingPoint in
      (
        id: boardingPoint.id,
        distance: distance(from: location, to: boardingPoint)
      )
    }
    .min { $0.distance < $1.distance }?
    .id
  }

  static func distance(from location: UserLocation, to boardingPoint: BoardingPoint) -> Double {
    let earthRadius = 6_371_000.0
    let latitudeDelta = radians(boardingPoint.centerLatitude - location.latitude)
    let longitudeDelta = radians(boardingPoint.centerLongitude - location.longitude)
    let sourceLatitude = radians(location.latitude)
    let destinationLatitude = radians(boardingPoint.centerLatitude)
    let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
      + cos(sourceLatitude) * cos(destinationLatitude)
      * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
    return earthRadius * 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
  }

  static func radians(_ degrees: Double) -> Double {
    degrees * .pi / 180
  }

  static func fetchUpcomingBuses(
    boardingPoint: BoardingPoint,
    fetchArrivals: @escaping @Sendable (_ stationId: Int) async throws -> [BusArrival]
  ) async throws -> [UpcomingBus] {
    var upcomingBuses: [UpcomingBus] = []

    for (busStop, busRoutes) in boardingPoint.routes {
      let busRouteIDs = Set(busRoutes.map(\.id))
      let arrivals = try await fetchArrivals(busStop.id)
      let matchingArrivals = arrivals.filter { busRouteIDs.contains($0.route.id) }
      for arrival in matchingArrivals {
        upcomingBuses.append(
          contentsOf: arrival.upcomingBuses(boardingPoint: boardingPoint, busStop: busStop)
        )
      }
    }

    return upcomingBuses.sortedByArrival
  }
}
