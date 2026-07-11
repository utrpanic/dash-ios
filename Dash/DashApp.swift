import ComposableArchitecture
import DashFeature
import SwiftUI

@main
struct DashApp: App {
  var body: some Scene {
    WindowGroup {
      DashboardView(
        store: Store(initialState: DashFeature.State()) {
          DashFeature()
        }
      )
    }
  }
}
