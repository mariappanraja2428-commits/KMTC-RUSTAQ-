class RecordModel {
  final String id;
  final String area;
  final String line;
  final String size;
  final String material;
  final String meter;
  final String txNo;
  final String place;
  final String beforeUrl;
  final String afterUrl;
  final double latitude;
  final double longitude;
  final bool deleted;
  final DateTime createdAt;

  RecordModel({
    required this.id,
    required this.area,
    required this.line,
    required this.size,
    required this.material,
    required this.meter,
    required this.txNo,
    required this.place,
    required this.beforeUrl,
    required this.afterUrl,
    required this.latitude,
    required this.longitude,
    required this.deleted,
    required this.createdAt,
  });

  factory RecordModel.fromMap(String id, Map<String, dynamic> m) {
    return RecordModel(
      id: id,
      area: m['area'] ?? '',
      line: m['line'] ?? '',
      size: m['size'] ?? '',
      material: m['material'] ?? '',
      meter: m['meter'] ?? '',
      txNo: m['txNo'] ?? '',
      place: m['place'] ?? '',
      beforeUrl: m['beforeUrl'] ?? '',
      afterUrl: m['afterUrl'] ?? '',
      latitude: (m['latitude'] ?? 0).toDouble(),
      longitude: (m['longitude'] ?? 0).toDouble(),
      deleted: m['deleted'] ?? false,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'area': area,
        'line': line,
        'size': size,
        'material': material,
        'meter': meter,
        'txNo': txNo,
        'place': place,
        'beforeUrl': beforeUrl,
        'afterUrl': afterUrl,
        'latitude': latitude,
        'longitude': longitude,
        'deleted': deleted,
        'createdAt': createdAt,
      };
}
