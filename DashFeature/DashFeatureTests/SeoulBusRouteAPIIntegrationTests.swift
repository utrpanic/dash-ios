import ComposableArchitecture
import Testing
@testable import DashFeature

private let seoulSampleRoute = BusRoute.seoul_662

@Test func searchSeoulBusRoutesThroughFeature() async throws {
  let routes = try await SeoulBusRouteAPIClient.liveValue.searchRoutes(seoulSampleRoute.number)
  let route = try #require(routes.first { $0.id == seoulSampleRoute.id })

  #expect(route == seoulSampleRoute)
}

@Test func fetchSeoulBusRouteInfoThroughFeature() async throws {
  let routeInfo = try await SeoulBusRouteAPIClient.liveValue.fetchRouteInfo(seoulSampleRoute.id)

  #expect(routeInfo.route == seoulSampleRoute)
  #expect(routeInfo.regionName == "서울")
  #expect(!routeInfo.startStationName.isEmpty)
  #expect(!routeInfo.endStationName.isEmpty)
}

@Test func fetchSeoulBusRouteStationsThroughFeature() async throws {
  let stations = try await SeoulBusRouteAPIClient.liveValue.fetchRouteStations(seoulSampleRoute.id)
  let firstStation = try #require(stations.first)

  #expect(firstStation.busStop.id > 0)
  #expect(!firstStation.busStop.name.isEmpty)
  #expect(firstStation.sequence > 0)
  #expect(firstStation.x > 0)
  #expect(firstStation.y > 0)
}

@Test func fetchSeoulBusRouteLineThroughFeature() async throws {
  let linePoints = try await SeoulBusRouteAPIClient.liveValue.fetchRouteLine(seoulSampleRoute.id)
  let firstPoint = try #require(linePoints.first)

  #expect(firstPoint.sequence > 0)
  #expect(firstPoint.x > 0)
  #expect(firstPoint.y > 0)
}
