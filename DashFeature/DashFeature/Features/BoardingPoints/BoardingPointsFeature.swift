import ComposableArchitecture

@Reducer
struct BoardingPointsFeature {
  @ObservableState
  struct State: Equatable {
    init() {}
  }
  
  enum Action: Equatable {
    case delegate(Delegate)

    enum Delegate: Equatable {
      case boardingPointSelected(BoardingPoint)
      case editBoardingPointRequested(BoardingPoint)
    }
  }
  
  init() {}
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .delegate:
        .none
      }
    }
  }
}
