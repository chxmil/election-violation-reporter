class ViolationType {
  final int typeId;
  final String typeName;
  final String severity; // 'High' | 'Medium' | 'Low'

  ViolationType({
    required this.typeId,
    required this.typeName,
    required this.severity,
  });

  factory ViolationType.fromMap(Map<String, dynamic> map) => ViolationType(
    typeId:   map['type_id'],
    typeName: map['type_name'],
    severity: map['severity'],
  );

  Map<String, dynamic> toMap() => {
    'type_id':   typeId,
    'type_name': typeName,
    'severity':  severity,
  };
}
