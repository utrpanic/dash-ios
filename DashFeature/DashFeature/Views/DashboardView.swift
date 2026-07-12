import ComposableArchitecture
import SwiftUI

public struct DashboardView: View {
  @Bindable private var store: StoreOf<DashFeature>

  public init(store: StoreOf<DashFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      r.color.background
        .ignoresSafeArea()
      VStack(spacing: 0) {
        DashboardHeaderView(store: store)
          .padding(.horizontal, 16)
          .padding(.top, 16)
        ScrollView {
          if store.isLoadingUpcomingBuses {
            ProgressView()
              .frame(maxWidth: .infinity)
              .padding(.top, 32)
          } else if let errorMessage = store.upcomingBusesErrorMessage {
            Text(errorMessage)
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(r.color.textSecondary)
              .frame(maxWidth: .infinity)
              .padding(.horizontal, 16)
              .padding(.top, 32)
          } else {
            TargetStopView(upcomingBuses: Array(store.upcomingBuses.sortedByArrival.prefix(5)))
              .padding(.horizontal, 16)
              .padding(.top, 16)
              .padding(.bottom, 16)
          }
        }
      }
    }
    .task {
      await store.send(.loadUpcomingBuses).finish()
    }
  }
}

struct DashboardHeaderView: View {
  @Bindable private var store: StoreOf<DashFeature>

  init(store: StoreOf<DashFeature>) {
    self.store = store
  }

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        targetStopMenu
        Spacer()
        Button {
          store.send(.addButtonTapped)
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 24, weight: .light))
            .foregroundStyle(r.color.brandMint)
            .frame(width: 44, height: 44)
            .background {
              Circle()
                .fill(r.color.surface)
                .shadow(color: r.color.shadow, radius: 12, y: 5)
            }
        }
        .buttonStyle(.plain)
      }
      Divider()
        .background(r.color.textSecondary.opacity(0.25))
    }
  }

  private var targetStopMenu: some View {
    Menu {
      ForEach(store.tabs) { tab in
        Button(tab.title) {
          store.send(.tabSelected(tab.id))
        }
      }
    } label: {
      HStack(spacing: 14) {
        Image(systemName: "location.circle.fill")
          .symbolRenderingMode(.palette)
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(.white, r.color.brandMint)
          .frame(width: 24, height: 24)
        Text(selectedTabTitle)
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(r.color.textPrimary)
        Image(systemName: "chevron.down")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(r.color.textSecondary)
      }
      .padding(.leading, 16)
      .padding(.trailing, 16)
      .frame(height: 44)
      .background {
        Capsule()
          .fill(r.color.surface)
          .overlay {
            Capsule()
              .stroke(r.color.textSecondary.opacity(0.16), lineWidth: 1)
          }
          .shadow(color: r.color.shadow, radius: 12, y: 5)
      }
    }
  }

  private var selectedTabTitle: String {
    store.tabs.first { $0.id == store.selectedTabID }?.title ?? ""
  }
}

#Preview("Light") {
  DashboardView(
    store: Store(initialState: DashFeature.State()) {
      DashFeature()
    }
  )
  .preferredColorScheme(.light)
}

#Preview("Dark") {
  DashboardView(
    store: Store(initialState: DashFeature.State()) {
      DashFeature()
    }
  )
  .preferredColorScheme(.dark)
}
