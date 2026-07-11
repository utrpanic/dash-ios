import SwiftUI

struct UpcomingBusView: View {
  let upcomingBus: UpcomingBus

  private var minutesRemaining: Int {
    max(0, Int(ceil(upcomingBus.arrivalDate.timeIntervalSince(.now) / 60)))
  }

  var body: some View {
    HStack(alignment: .center, spacing: 18) {
      VStack(alignment: .leading, spacing: 10) {
        Text(upcomingBus.target.busRoute.number)
          .font(.system(size: 40, weight: .semibold, design: .default))
          .foregroundStyle(r.color.textPrimary)

        VStack(alignment: .leading, spacing: 6) {
          Label(upcomingBus.target.busStop.alias ?? upcomingBus.target.busStop.name, systemImage: "mappin.circle")
          Label(upcomingBus.arrivalDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
        }
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(r.color.textSecondary)
        .labelStyle(.titleAndIcon)
      }
      Spacer(minLength: 16)
      VStack(spacing: 0) {
        Text("\(minutesRemaining)")
          .font(.system(size: 48, weight: timeWeight, design: .default))
          .foregroundStyle(r.color.brandMint)
          .monospacedDigit()
        Text("min")
          .font(.system(size: 24, weight: timeWeight, design: .default))
          .foregroundStyle(r.color.brandMint)
      }
      .frame(minWidth: 70)
    }
    .padding(.horizontal, 26)
    .padding(.vertical, 24)
    .background {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(r.color.surface)
        .shadow(color: r.color.shadow, radius: 12, y: 5)
    }
  }

  private var timeWeight: Font.Weight {
    switch minutesRemaining {
    case ...2:
      return .bold
    case 3...10:
      return .medium
    default:
      return .light
    }
  }
}
