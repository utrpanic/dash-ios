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
        } else if let targetStopSelectionMessage {
          Spacer()
          Text(targetStopSelectionMessage)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(r.color.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
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
              .padding(.bottom, 84)
          }
        }
      }
      VStack {
        Spacer()
        HStack {
          Spacer()
          refreshButton
        }
      }
      .padding(.trailing, 32)
      .padding(.bottom, 32)
      .ignoresSafeArea(.container, edges: [.bottom, .trailing])
    }
    .task {
      store.send(.task)
    }
  }

  private var refreshButton: some View {
    Button {
      store.send(.refreshButtonTapped)
    } label: {
      Image(systemName: "arrow.clockwise")
        .font(.system(size: 21, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 64, height: 64)
        .background(r.color.brandMint, in: Circle())
        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
    }
    .buttonStyle(.plain)
    .disabled(isRefreshDisabled)
    .opacity(isRefreshDisabled ? 0.55 : 1)
    .accessibilityLabel("새로고침")
  }

  private var isRefreshDisabled: Bool {
    store.isLoadingUpcomingBuses || store.selectedTabID == nil
  }

  private var targetStopSelectionMessage: String? {
    switch store.targetStopSelection {
    case .locating:
      return "현재 위치를 확인하고 있습니다."
    case .locationPermissionDenied:
      return "위치 권한이 없습니다.\n상단에서 목적지를 선택해주세요."
    case .locationUnavailable:
      return "현재 위치를 확인할 수 없습니다.\n상단에서 목적지를 선택해주세요."
    case .selected:
      return nil
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
        Button {
          store.send(.editButtonTapped)
        } label: {
          Image(systemName: "square.and.pencil")
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(r.color.textSecondary)
            .frame(width: 44, height: 44)
            .offset(y: -2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("편집")
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
            .id(store.targetStopSelection)
            .transition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .animation(targetStopSwitchAnimation, value: store.targetStopSelection)
      }
      .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
    .buttonStyle(.plain)
    .disabled(store.targetStopSelection == .locating || store.tabs.isEmpty)
  }

  private var targetStopTitleLabel: some View {
    HStack(spacing: 6) {
      Text(targetStopTitle)
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(targetStopTitleColor)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      if store.targetStopSelection != .locating {
        Image(systemName: "chevron.right")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(r.color.textSecondary)
      }
    }
  }

  private var targetStopTitle: String {
    switch store.targetStopSelection {
    case .locating:
      return "위치 확인 중…"
    case .locationPermissionDenied:
      return "위치 권한 없음"
    case .locationUnavailable:
      return "위치 확인 불가"
    case let .selected(tabID):
      return store.tabs.first { $0.id == tabID }?.title ?? ""
    }
  }

  private var targetStopTitleColor: Color {
    switch store.targetStopSelection {
    case .selected:
      return r.color.textPrimary
    case .locating, .locationPermissionDenied, .locationUnavailable:
      return r.color.textSecondary
    }
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
