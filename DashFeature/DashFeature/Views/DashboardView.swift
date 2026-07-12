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
        if store.isLoadingUpcomingBuses {
          Spacer()
          ProgressView()
            .frame(maxWidth: .infinity)
          Spacer()
        } else if let errorMessage = store.upcomingBusesErrorMessage {
          Spacer()
          Text(errorMessage)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(r.color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
          Spacer()
        } else {
          ScrollView {
            TargetStopView(upcomingBuses: Array(store.upcomingBuses.sortedByArrival.prefix(5)))
              .padding(.horizontal, 16)
              .padding(.top, 16)
              .padding(.bottom, 16)
          }
        }
      }
    }
    .task {
      store.send(.loadUpcomingBuses)
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
      HStack(spacing: 16) {
        targetStopButton
        Spacer(minLength: 16)
        Button {
          store.send(.addButtonTapped)
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 27, weight: .light))
            .foregroundStyle(r.color.textSecondary)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
      }
      Divider()
        .background(r.color.textSecondary.opacity(0.25))
    }
  }

  private var targetStopButton: some View {
    Button {
      store.send(.nextTargetStopButtonTapped)
    } label: {
      HStack(spacing: 12) {
        Image(systemName: "location.circle.fill")
          .symbolRenderingMode(.palette)
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(.white, r.color.brandMint)
          .frame(width: 20, height: 20)
        ZStack(alignment: .leading) {
          targetStopTitleLabel
            .id(store.selectedTabID)
            .transition(.opacity)
        }
        .clipped()
        .animation(targetStopSwitchAnimation, value: store.selectedTabID)
      }
      .frame(minHeight: 44, alignment: .leading)
    }
    .buttonStyle(.plain)
  }

  private var targetStopTitleLabel: some View {
    HStack(spacing: 6) {
      Text(selectedTabTitle)
        .font(.system(size: 24, weight: .medium))
        .foregroundStyle(r.color.textPrimary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      Image(systemName: "chevron.right")
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(r.color.textSecondary)
    }
  }

  private var selectedTabTitle: String {
    store.tabs.first { $0.id == store.selectedTabID }?.title ?? ""
  }

  private var targetStopSwitchAnimation: Animation {
    .easeInOut(duration: 0.2)
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
