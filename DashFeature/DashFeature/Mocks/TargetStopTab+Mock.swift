extension Array where Element == TargetStopTab {
  static var mock: [TargetStopTab] {
    [
      .init(id: "yeongdeungpo", title: "영등포"),
      .init(id: "suwon-station", title: "수원역"),
      .init(id: "hyundai-department-store", title: "현대백화점"),
    ]
  }
}
