extension Array where Element == TargetStopTab {
  static var mock: [TargetStopTab] {
    [
      .init(
        id: "suwon-station",
        title: "수원역",
        targetStops: [
          .suwonStation,
        ],
        busRoutes: [
          .gyeonggi_13,
          .gyeonggi_13_1,
          .gyeonggi_13_4,
          .gyeonggi_13_5,
          .gyeonggi_15_1,
        ]
      ),
      .init(
        id: "homaesil-ssangyong-apartment",
        title: "호매실쌍용아파트",
        targetStops: [
          .homaesilSsangyongApartment,
        ],
        busRoutes: [
          .gyeonggi_9,
          .gyeonggi_9_1,
          .gyeonggi_13,
        ]
      ),
    ]
  }
}
