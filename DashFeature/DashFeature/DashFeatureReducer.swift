import ComposableArchitecture

@Reducer
public struct DashFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var tabs: [TargetStopTab]
    public var selectedTabID: TargetStopTab.ID
    public var upcomingBuses: [UpcomingBus]

    public init() {
      self.tabs = .mock
      self.selectedTabID = "suwon-station"
      self.upcomingBuses = .mock
    }
  }

  public enum Action: Equatable {
    case addButtonTapped
    case tabSelected(TargetStopTab.ID)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        return .none

      case let .tabSelected(tabID):
        state.selectedTabID = tabID
        return .none
      }
    }
  }
}
