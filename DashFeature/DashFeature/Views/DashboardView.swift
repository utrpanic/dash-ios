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
        } else if let boardingPointSelectionMessage {
          Spacer()
          Text(boardingPointSelectionMessage)
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
            BoardingPointView(upcomingBuses: Array(store.upcomingBuses.sortedByArrival.prefix(5)))
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
    store.isLoadingUpcomingBuses || store.selectedBoardingPointID == nil
  }

  private var boardingPointSelectionMessage: String? {
    switch store.boardingPointSelection {
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
        boardingPointButton
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

  private var boardingPointButton: some View {
    Button {
      store.send(.nextBoardingPointButtonTapped)
    } label: {
      HStack(spacing: 12) {
        boardingPointTitleIcon
        boardingPointTitleLabel
          .animation(nil, value: store.boardingPointSelection)
      }
      .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
    .buttonStyle(.plain)
    .disabled(store.boardingPointSelection == .locating || store.boardingPoints.isEmpty)
  }

  private var boardingPointTitleIcon: some View {
    Image(systemName: "location.circle.fill")
      .symbolRenderingMode(.palette)
      .font(.system(size: 24, weight: .semibold))
      .foregroundStyle(.white, r.color.brandMint)
      .frame(width: 20, height: 20)
  }

  private var boardingPointTitleLabel: some View {
    let (title, showTrailingIcon) = switch store.boardingPointSelection {
    case .locating:
      ("위치 확인 중…", false)
    case .locationPermissionDenied:
      ("위치 권한 없음", true)
    case .locationUnavailable:
      ("위치 확인 불가", true)
    case let .selected(boardingPointID):
      (store.boardingPoints.first { $0.id == boardingPointID }?.name ?? "", true)
    }
    return HStack(spacing: 8) {
      Text(title)
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(boardingPointTitleColor)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      if showTrailingIcon {
        Image(systemName: "chevron.right")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(r.color.textSecondary)
      }
    }
  }

  private var boardingPointTitleColor: Color {
    switch store.boardingPointSelection {
    case .selected:
      return r.color.textPrimary
    case .locating, .locationPermissionDenied, .locationUnavailable:
      return r.color.textSecondary
    }
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
