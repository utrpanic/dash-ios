import ComposableArchitecture
import DashFeature
import SwiftUI

@main
struct DashApp: App {
  var body: some Scene {
    WindowGroup {
      DashFeatureView(
        store: Store(initialState: DashFeatureState()) {
          DashFeatureReducer()
        }
      )
    }
  }
}
