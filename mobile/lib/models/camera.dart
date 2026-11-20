/// Camera model aligned with backend `CameraOut` schema (`backend/app/schemas/__init__.py`).
class Camera {
  final String id;
  final String name;
  final String rtspUrl;
  final String? location;
  final double confThreshold;
  final bool isActive;
  final DateTime createdAt;

  const Camera({
    required this.id,
    required this.name,
    required this.rtspUrl,
    this.location,
    required this.confThreshold,
    required this.isActive,
    required this.createdAt,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id'] as String,
      name: json['name'] as String,
      rtspUrl: json['rtsp_url'] as String,
      location: json['location'] as String?,
      confThreshold: (json['conf_threshold'] as num?)?.toDouble() ?? 0.45,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rtsp_url': rtspUrl,
        'location': location,
        'conf_threshold': confThreshold,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };
}
