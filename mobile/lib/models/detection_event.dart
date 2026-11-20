/// Detection bounding box aligned with backend `BoxOut` schema.
class DetectionBox {
  final String id;
  final String className; // 'flame' | 'smoke'
  final double confidence;
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;

  const DetectionBox({
    required this.id,
    required this.className,
    required this.confidence,
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
  });

  bool get isFlame => className.toLowerCase() == 'flame';

  factory DetectionBox.fromJson(Map<String, dynamic> json) {
    return DetectionBox(
      id: json['id'] as String? ?? '',
      className: json['class_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      xMin: (json['x_min'] as num).toDouble(),
      yMin: (json['y_min'] as num).toDouble(),
      xMax: (json['x_max'] as num).toDouble(),
      yMax: (json['y_max'] as num).toDouble(),
    );
  }
}

/// Detection event aligned with backend `EventOut` schema (`detection_events` + `detection_boxes`).
class DetectionEvent {
  final String id;
  final String cameraId;
  final String? cameraName;
  final String? cameraLocation;
  final String eventType; // 'flame' | 'smoke' | 'both'
  final double maxConfidence;
  final int frameStreak;
  final String? snapshotPath;
  final DateTime detectedAt;
  final List<DetectionBox> boxes;
  final bool acknowledged;

  const DetectionEvent({
    required this.id,
    required this.cameraId,
    this.cameraName,
    this.cameraLocation,
    required this.eventType,
    required this.maxConfidence,
    required this.frameStreak,
    this.snapshotPath,
    required this.detectedAt,
    required this.boxes,
    this.acknowledged = false,
  });

  DetectionEvent copyWith({
    String? cameraName,
    String? cameraLocation,
    bool? acknowledged,
  }) {
    return DetectionEvent(
      id: id,
      cameraId: cameraId,
      cameraName: cameraName ?? this.cameraName,
      cameraLocation: cameraLocation ?? this.cameraLocation,
      eventType: eventType,
      maxConfidence: maxConfidence,
      frameStreak: frameStreak,
      snapshotPath: snapshotPath,
      detectedAt: detectedAt,
      boxes: boxes,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  factory DetectionEvent.fromJson(Map<String, dynamic> json) {
    final rawBoxes = (json['boxes'] as List<dynamic>? ?? []);
    return DetectionEvent(
      id: json['id'] as String,
      cameraId: json['camera_id'] as String,
      cameraName: json['camera_name'] as String?,
      cameraLocation: json['camera_location'] as String?,
      eventType: json['event_type'] as String,
      maxConfidence: (json['max_confidence'] as num).toDouble(),
      frameStreak: (json['frame_streak'] as num).toInt(),
      snapshotPath: json['snapshot_path'] as String?,
      detectedAt: DateTime.parse(json['detected_at'] as String),
      boxes: rawBoxes
          .map((e) => DetectionBox.fromJson(e as Map<String, dynamic>))
          .toList(),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }
}
