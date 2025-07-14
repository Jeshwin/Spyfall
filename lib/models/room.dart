import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus { setup, waiting, inProgress, completed }

class RoomSettings {
  final int discussionTime;
  final int votingTime;
  final bool startTimerOnGameStart;

  RoomSettings({
    required this.discussionTime,
    required this.votingTime,
    required this.startTimerOnGameStart,
  });

  Map<String, dynamic> toJson() {
    return {
      'discussionTime': discussionTime,
      'votingTime': votingTime,
      'startTimerOnGameStart': startTimerOnGameStart,
    };
  }

  static RoomSettings fromJson(Map<String, dynamic> json) {
    return RoomSettings(
      discussionTime: json['discussionTime'] ?? 480,
      votingTime: json['votingTime'] ?? 120,
      startTimerOnGameStart: json['startTimerOnGameStart'] ?? true,
    );
  }
}

class Room {
  final String id;
  final String roomCode;
  final RoomStatus status;
  final String? location;
  final String? spyId;
  final Timestamp? roundStartTime;
  final Timestamp createdAt;
  final String createdBy;
  final RoomSettings settings;

  Room({
    required this.id,
    required this.roomCode,
    required this.status,
    this.location,
    this.spyId,
    this.roundStartTime,
    required this.createdAt,
    required this.createdBy,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomCode': roomCode,
      'status': status.name,
      'location': location,
      'spyId': spyId,
      'roundStartTime': roundStartTime,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'settings': settings.toJson(),
    };
  }

  static Room fromJson(Map<String, dynamic> json, String roomCode) {
    return Room(
      id: roomCode,
      roomCode: roomCode,
      status: RoomStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RoomStatus.setup,
      ),
      location: json['location'],
      spyId: json['spyId'],
      roundStartTime: json['roundStartTime'],
      createdAt: json['createdAt'] ?? Timestamp.now(),
      createdBy: json['createdBy'] ?? '',
      settings: RoomSettings.fromJson(json['settings'] ?? {}),
    );
  }

  Room copyWith({
    String? id,
    String? roomCode,
    RoomStatus? status,
    String? location,
    String? spyId,
    Timestamp? roundStartTime,
    Timestamp? createdAt,
    String? createdBy,
    RoomSettings? settings,
  }) {
    return Room(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      status: status ?? this.status,
      location: location ?? this.location,
      spyId: spyId ?? this.spyId,
      roundStartTime: roundStartTime ?? this.roundStartTime,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      settings: settings ?? this.settings,
    );
  }
}
