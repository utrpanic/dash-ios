import ComposableArchitecture
import Foundation

@ObservableState
public struct DashFeatureState: Equatable {
  public enum BoardingPointSelection: Equatable, Hashable {
    case locating
    case locationPermissionDenied
    case locationUnavailable
    case selected(BoardingPoint.ID)
  }

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
