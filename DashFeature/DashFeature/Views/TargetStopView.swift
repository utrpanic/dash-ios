import SwiftUI

struct TargetStopView: View {
  let upcomingBuses: [UpcomingBus]

  var body: some View {
    LazyVStack(spacing: 12) {
      ForEach(upcomingBuses) { upcomingBus in
        UpcomingBusView(upcomingBus: upcomingBus)
      }
    }
  }
}
