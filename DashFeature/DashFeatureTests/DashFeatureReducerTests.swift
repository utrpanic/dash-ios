import ComposableArchitecture
import Testing
@testable import DashFeature

@MainActor
@Test func reducerLoadsUpcomingBusesAfterSelectingBoardingPoint() async {
  let expectedUpcomingBus = UpcomingBus(
    boardingPoint: .homaesilSsangyongApartment,
    busStop: .homaesilSsangyongApartment,
    busRoute: .gyeonggi_9,
    timeIntervalUntilArrival: 3 * 60
  )
  let store = TestStore(initialState: DashFeature.State()) {
    DashFeature()
  } withDependencies: {
    $0.busArrivalAPIClient.fetchArrivals = { stationId in
      guard stationId == BusStop.homaesilSsangyongApartment.id else {
        return []
      }

      return [
        BusArrival(
          stationId: stationId,
          route: .gyeonggi_9,
          stationOrder: 2,
          destinationName: "",
          operationState: "",
          firstPrediction: BusArrivalPrediction(
            minutes: 3,
            seconds: nil,
            locationNumber: nil,
            plateNumber: "",
            remainingSeatCount: nil,
            stateCode: nil,
            stationName: "",
            vehicleId: nil
          ),
          secondPrediction: nil
        )
      ]
    }
  }

  await store.send(.boardingPointSelected("homaesil-ssangyong-apartment")) {
    $0.boardingPointSelection = .selected("homaesil-ssangyong-apartment")
  }
  await store.receive(.loadUpcomingBuses) {
    $0.isLoadingUpcomingBuses = true
    $0.upcomingBusesErrorMessage = nil
  }
  await store.receive(.loadUpcomingBusesResponse(.success([expectedUpcomingBus]))) {
    $0.isLoadingUpcomingBuses = false
    $0.upcomingBuses = [expectedUpcomingBus]
    $0.upcomingBusesErrorMessage = nil
  }
}

@MainActor
@Test func reducerSelectsNextBoardingPoint() async {
  var initialState = DashFeature.State()
  initialState.boardingPointSelection = .selected("suwon-station")
  let store = TestStore(initialState: initialState) {
    DashFeature()
  } withDependencies: {
    $0.busArrivalAPIClient.fetchArrivals = { _ in [] }
  }

  await store.send(.nextBoardingPointButtonTapped) {
    $0.boardingPointSelection = .selected("homaesil-ssangyong-apartment")
  }
  await store.receive(.loadUpcomingBuses) {
    $0.isLoadingUpcomingBuses = true
    $0.upcomingBusesErrorMessage = nil
  }
  await store.receive(.loadUpcomingBusesResponse(.success([]))) {
    $0.isLoadingUpcomingBuses = false
    $0.upcomingBuses = []
    $0.upcomingBusesErrorMessage = nil
  }

  await store.send(.nextBoardingPointButtonTapped) {
    $0.boardingPointSelection = .selected("yeongdeungpo-station")
  }
  await store.receive(.loadUpcomingBuses) {
    $0.isLoadingUpcomingBuses = true
    $0.upcomingBusesErrorMessage = nil
  }
  await store.receive(.loadUpcomingBusesResponse(.success([]))) {
    $0.isLoadingUpcomingBuses = false
    $0.upcomingBuses = []
    $0.upcomingBusesErrorMessage = nil
  }

  await store.send(.nextBoardingPointButtonTapped) {
    $0.boardingPointSelection = .selected("the-hyundai-seoul")
  }
  await store.receive(.loadUpcomingBuses) {
    $0.isLoadingUpcomingBuses = true
    $0.upcomingBusesErrorMessage = nil
  }
  await store.receive(.loadUpcomingBusesResponse(.success([]))) {
    $0.isLoadingUpcomingBuses = false
    $0.upcomingBuses = []
    $0.upcomingBusesErrorMessage = nil
  }

  await store.send(.nextBoardingPointButtonTapped) {
    $0.boardingPointSelection = .selected("suwon-station")
  }
  await store.receive(.loadUpcomingBuses) {
    $0.isLoadingUpcomingBuses = true
    $0.upcomingBusesErrorMessage = nil
  }
  await store.receive(.loadUpcomingBusesResponse(.success([]))) {
    $0.isLoadingUpcomingBuses = false
    $0.upcomingBuses = []
    $0.upcomingBusesErrorMessage = nil
  }
}

@MainActor
@Test func reducerSelectsNearestBoardingPointOnTask() async {
  let location = UserLocation(
    latitude: BoardingPoint.homaesilSsangyongApartment.centerLatitude,
    longitude: BoardingPoint.homaesilSsangyongApartment.centerLongitude
  )
  let store = TestStore(initialState: DashFeature.State()) {
    DashFeature()
  } withDependencies: {
    $0.userLocationClient.requestLocation = { location }
    $0.busArrivalAPIClient.fetchArrivals = { _ in [] }
  }

  await store.send(.task) {
    $0.hasRequestedInitialLocation = true
    $0.isLoadingUpcomingBuses = true
  }
  await store.receive(.userLocationResponse(.success(location))) {
    $0.boardingPointSelection = .selected("homaesil-ssangyong-apartment")
  }
  await store.receive(.loadUpcomingBuses)
  await store.receive(.loadUpcomingBusesResponse(.success([]))) {
    $0.isLoadingUpcomingBuses = false
    $0.upcomingBuses = []
    $0.upcomingBusesErrorMessage = nil
  }
}

@Test func boardingPointUsesCenterOfBusStops() {
  let boardingPoint = BoardingPoint(
    id: "test",
    name: "Test",
    routes: [
      BusStop(id: 1, name: "First", latitude: 37, longitude: 126): [],
      BusStop(id: 2, name: "Second", latitude: 39, longitude: 128): [],
    ]
  )

  #expect(boardingPoint.centerLatitude == 38)
  #expect(boardingPoint.centerLongitude == 127)
}

@MainActor
@Test func reducerRefreshesWithoutChangingBoardingPoint() async {
  var initialState = DashFeature.State()
  initialState.boardingPointSelection = .selected("homaesil-ssangyong-apartment")
  let store = TestStore(initialState: initialState) {
    DashFeature()
  } withDependencies: {
    $0.busArrivalAPIClient.fetchArrivals = { _ in [] }
  }

  await store.send(.refreshButtonTapped)
  await store.receive(.loadUpcomingBuses) {
    $0.isLoadingUpcomingBuses = true
    $0.upcomingBusesErrorMessage = nil
  }
  await store.receive(.loadUpcomingBusesResponse(.success([]))) {
    $0.isLoadingUpcomingBuses = false
    $0.upcomingBuses = []
    $0.upcomingBusesErrorMessage = nil
  }
}

@MainActor
@Test func reducerRepresentsDeniedLocationPermission() async {
  let store = TestStore(initialState: DashFeature.State()) {
    DashFeature()
  } withDependencies: {
    $0.userLocationClient.requestLocation = {
      throw UserLocationError.authorizationDenied
    }
  }

  await store.send(.task) {
    $0.hasRequestedInitialLocation = true
    $0.isLoadingUpcomingBuses = true
  }
  await store.receive(.userLocationResponse(.authorizationDenied)) {
    $0.boardingPointSelection = .locationPermissionDenied
    $0.isLoadingUpcomingBuses = false
  }
}
