import ComposableArchitecture
import Testing
@testable import DashFeature

@MainActor
@Test func reducerLoadsUpcomingBusesAfterSelectingTab() async {
  let expectedUpcomingBus = UpcomingBus(
    targetStop: .homaesilSsangyongApartment,
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

  await store.send(.tabSelected("homaesil-ssangyong-apartment")) {
    $0.selectedTabID = "homaesil-ssangyong-apartment"
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
@Test func reducerSelectsNextTargetStop() async {
  let store = TestStore(initialState: DashFeature.State()) {
    DashFeature()
  } withDependencies: {
    $0.busArrivalAPIClient.fetchArrivals = { _ in [] }
  }

  await store.send(.nextTargetStopButtonTapped) {
    $0.selectedTabID = "homaesil-ssangyong-apartment"
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

  await store.send(.nextTargetStopButtonTapped) {
    $0.selectedTabID = "suwon-station"
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
