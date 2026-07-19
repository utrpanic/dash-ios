import ComposableArchitecture
import SwiftUI

public struct DashFeatureView: View {
  @Bindable private var store: StoreOf<DashFeatureReducer>

  public init(store: StoreOf<DashFeatureReducer>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
      content
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            DashNavigationTitleView(store: store)
              .fixedSize(horizontal: true, vertical: false)
              .transaction {
                $0.animation = nil
                $0.disablesAnimations = true
              }
          }
          .sharedBackgroundVisibility(.hidden)
          ToolbarItem(placement: .topBarTrailing) {
            DashNavigationTrailingView(store: store)
          }
          .sharedBackgroundVisibility(.hidden)
        }
        .toolbarBackground(r.color.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
  }

  private var content: some View {
    ZStack {
      r.color.background
        .ignoresSafeArea()
      VStack(spacing: 0) {
        Divider()
          .background(r.color.textSecondary.opacity(0.25))
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
          Spacer()
        } else if let errorMessage = store.upcomingBusesErrorMessage {
          Spacer()
          Text(errorMessage)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(r.color.textSecondary)
            .frame(maxWidth: .infinity)
          Spacer()
        } else {
          ScrollView {
            BoardingPointView(upcomingBuses: Array(store.upcomingBuses.sortedByArrival.prefix(5)))
              .padding(.top, 16)
              .padding(.bottom, 84)
          }
        }
      }
      .padding(.horizontal, 16)
      VStack {
        Spacer()
        HStack {
          Spacer()
          floatingButtons
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

  private var floatingButtons: some View {
    VStack(spacing: 16) {
      locationButton
      refreshButton
        .overlay(alignment: .bottom) {
          elapsedTimeLabel
            .offset(y: 20)
            .allowsHitTesting(false)
        }
    }
  }

  private var locationButton: some View {
    Button {
      store.send(.locationButtonTapped)
    } label: {
      Image(systemName: "location.fill")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(r.color.brandMint)
        .frame(width: 64, height: 64)
        .background(r.color.surface, in: Circle())
        .shadow(color: .black.opacity(0.14), radius: 7, y: 2)
    }
    .buttonStyle(.plain)
    .disabled(areFloatingButtonsDisabled)
    .opacity(areFloatingButtonsDisabled ? 0.55 : 1)
    .accessibilityLabel("현재 위치")
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
    .disabled(areFloatingButtonsDisabled)
    .opacity(areFloatingButtonsDisabled ? 0.55 : 1)
    .accessibilityLabel("새로고침")
  }

  @ViewBuilder
  private var elapsedTimeLabel: some View {
    if !store.isLoadingUpcomingBuses, let lastUpdatedAt = store.lastUpdatedAt {
      TimelineView(.periodic(from: .now, by: 1)) { context in
        if context.date.timeIntervalSince(lastUpdatedAt) >= 10 {
          Text(elapsedTimeText(from: lastUpdatedAt, to: context.date))
            .font(.system(size: 12, weight: .regular))
            .monospacedDigit()
            .foregroundStyle(r.color.textSecondary.opacity(0.6))
            .frame(width: 64)
            .accessibilityLabel(
              elapsedTimeAccessibilityLabel(from: lastUpdatedAt, to: context.date)
            )
        }
      }
    }
  }

  private var areFloatingButtonsDisabled: Bool {
    store.isLoadingUpcomingBuses || store.boardingPointIsNotAvailable
  }

  private func elapsedTimeText(from startDate: Date, to endDate: Date) -> String {
    let elapsedSeconds = max(Int(endDate.timeIntervalSince(startDate)), 0)
    if elapsedSeconds < 60 {
      return "\(elapsedSeconds)s ago"
    }
    if elapsedSeconds < 60 * 60 {
      return "\(elapsedSeconds / 60)m ago"
    }
    return "\(elapsedSeconds / 60 / 60)h ago"
  }

  private func elapsedTimeAccessibilityLabel(from startDate: Date, to endDate: Date) -> String {
    let elapsedSeconds = max(Int(endDate.timeIntervalSince(startDate)), 0)
    if elapsedSeconds < 60 {
      let unit = elapsedSeconds == 1 ? "second" : "seconds"
      return "Updated \(elapsedSeconds) \(unit) ago"
    }
    if elapsedSeconds < 60 * 60 {
      let elapsedMinutes = elapsedSeconds / 60
      let unit = elapsedMinutes == 1 ? "minute" : "minutes"
      return "Updated \(elapsedMinutes) \(unit) ago"
    }
    let elapsedHours = elapsedSeconds / 60 / 60
    let unit = elapsedHours == 1 ? "hour" : "hours"
    return "Updated \(elapsedHours) \(unit) ago"
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

struct DashNavigationTitleView: View {
  @Bindable private var store: StoreOf<DashFeatureReducer>

  init(store: StoreOf<DashFeatureReducer>) {
    self.store = store
  }

  var body: some View {
    boardingPointButton
  }

  private var boardingPointButton: some View {
    Button {
      store.send(.nextBoardingPointButtonTapped)
    } label: {
      HStack(spacing: 8) {
        boardingPointTitleIcon
        boardingPointTitleLabel
      }
    }
    .buttonStyle(.plain)
    .disabled(store.boardingPointSelection == .locating || store.boardingPoints.isEmpty)
  }

  private var boardingPointTitleIcon: some View {
    Image(systemName: "location.circle.fill")
      .symbolRenderingMode(.palette)
      .font(.system(size: 24, weight: .semibold))
      .foregroundStyle(.white, r.color.brandMint)
  }

  private var boardingPointTitleLabel: some View {
    let (title, showTrailingIcon) = switch store.boardingPointSelection {
    case .locating:
      ("위치 확인 중…", false)
    case .locationPermissionDenied:
      ("위치 권한 없음", false)
    case .locationUnavailable:
      ("위치 확인 불가", false)
    case let .selected(boardingPointID):
      (store.boardingPoints.first { $0.id == boardingPointID }?.name ?? "", true)
    }
    return HStack(spacing: 8) {
      Text(title)
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(boardingPointTitleColor)
        .lineLimit(1)
        .frame(maxWidth: 160, alignment: .leading)
      if showTrailingIcon {
        Image(systemName: "chevron.right")
          .font(.system(size: 16, weight: .medium))
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

struct DashNavigationTrailingView: View {
  @Bindable private var store: StoreOf<DashFeatureReducer>

  init(store: StoreOf<DashFeatureReducer>) {
    self.store = store
  }
  
  var body: some View {
    HStack(spacing: 0) {
      Button {
        store.send(.editButtonTapped)
      } label: {
        Image(systemName: "square.and.pencil")
          .padding(.horizontal, 4)
      }
      .tint(r.color.textSecondary)
      .disabled(store.boardingPointIsNotAvailable)
      .accessibilityLabel("편집")
      Button {
        
      } label: {
        Image(systemName: "list.bullet")
          .offset(x: 0, y: 2)
          .padding(.horizontal, 4)
      }
      .tint(r.color.textSecondary)
      .accessibilityLabel("목록")
    }
  }
}

#Preview("Light") {
  DashFeatureView(
    store: Store(initialState: .preview) {
      DashFeatureReducer()
    }
  )
  .preferredColorScheme(.light)
}

#Preview("Dark") {
  DashFeatureView(
    store: Store(initialState: .preview) {
      DashFeatureReducer()
    }
  )
  .preferredColorScheme(.dark)
}

private extension DashFeatureState {
  static var preview: Self {
    var state = Self()
    state.boardingPointSelection = .selected(BoardingPoint.suwonStation.id)
    state.hasRequestedInitialLocation = true
    state.upcomingBuses = .mock
    state.lastUpdatedAt = .now.addingTimeInterval(-12)
    return state
  }
}
