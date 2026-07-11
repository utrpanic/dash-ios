import Foundation

extension Array where Element == UpcomingBus {
  static var mock: [UpcomingBus] {
    let outerStop = BusStop(id: 1, name: "Suwon Station", alias: "Outer Platform")
    let innerStop = BusStop(id: 2, name: "Suwon Station", alias: "Inner Platform")

    let route13 = BusRoute(id: 13, number: "13")
    let route134 = BusRoute(id: 134, number: "13-4")
    let route131 = BusRoute(id: 131, number: "13-1")
    let route135 = BusRoute(id: 135, number: "13-5")

    return [
      UpcomingBus(
        target: TargetStop(busStop: outerStop, busRoute: route13),
        arrivalDate: .now.addingTimeInterval(2 * 60)
      ),
      UpcomingBus(
        target: TargetStop(busStop: outerStop, busRoute: route134),
        arrivalDate: .now.addingTimeInterval(7 * 60)
      ),
      UpcomingBus(
        target: TargetStop(busStop: innerStop, busRoute: route131),
        arrivalDate: .now.addingTimeInterval(12 * 60)
      ),
      UpcomingBus(
        target: TargetStop(busStop: innerStop, busRoute: route135),
        arrivalDate: .now.addingTimeInterval(26 * 60)
      ),
    ]
  }
}
