class PollingStation {
  final int stationId;
  final String stationName;
  final String zone;
  final String province;

  PollingStation({
    required this.stationId,
    required this.stationName,
    required this.zone,
    required this.province,
  });

  factory PollingStation.fromMap(Map<String, dynamic> map) => PollingStation(
    stationId:   map['station_id'],
    stationName: map['station_name'],
    zone:        map['zone'],
    province:    map['province'],
  );

  Map<String, dynamic> toMap() => {
    'station_id':   stationId,
    'station_name': stationName,
    'zone':         zone,
    'province':     province,
  };
}
