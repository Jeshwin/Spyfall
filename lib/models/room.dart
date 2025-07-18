import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spyfall/constants/constants.dart';

enum RoomStatus { setup, waiting, inProgress, completed, closed }

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
      discussionTime:
          json['discussionTime'] ??
          AppConstants.defaultSettings["discussionTime"],
      votingTime:
          json['votingTime'] ?? AppConstants.defaultSettings["votingTime"],
      startTimerOnGameStart:
          json['startTimerOnGameStart'] ??
          AppConstants.defaultSettings["startTimerOnGameStart"],
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
  final int gameSession;
  final Timestamp createdAt;
  final String createdBy;
  final RoomSettings settings;
  final bool isTimerPaused;
  final Timestamp? timerLastUpdated;

  Room({
    required this.id,
    required this.roomCode,
    required this.status,
    this.location,
    this.spyId,
    this.roundStartTime,
    this.gameSession = 0,
    required this.createdAt,
    required this.createdBy,
    required this.settings,
    this.isTimerPaused = false,
    this.timerLastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomCode': roomCode,
      'status': status.name,
      'location': location,
      'spyId': spyId,
      'roundStartTime': roundStartTime,
      'gameSession': gameSession,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'settings': settings.toJson(),
      'isTimerPaused': isTimerPaused,
      'timerLastUpdated': timerLastUpdated,
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
      gameSession: json['gameSession'] ?? 0,
      createdAt: json['createdAt'] ?? Timestamp.now(),
      createdBy: json['createdBy'] ?? '',
      settings: RoomSettings.fromJson(json['settings'] ?? {}),
      isTimerPaused: json['isTimerPaused'] ?? false,
      timerLastUpdated: json['timerLastUpdated'],
    );
  }

  Room copyWith({
    String? id,
    String? roomCode,
    RoomStatus? status,
    String? location,
    String? spyId,
    Timestamp? roundStartTime,
    int? gameSession,
    Timestamp? createdAt,
    String? createdBy,
    RoomSettings? settings,
    bool? isTimerPaused,
    Timestamp? timerLastUpdated,
  }) {
    return Room(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      status: status ?? this.status,
      location: location ?? this.location,
      spyId: spyId ?? this.spyId,
      roundStartTime: roundStartTime ?? this.roundStartTime,
      gameSession: gameSession ?? this.gameSession,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      settings: settings ?? this.settings,
      isTimerPaused: isTimerPaused ?? this.isTimerPaused,
      timerLastUpdated: timerLastUpdated ?? this.timerLastUpdated,
    );
  }
}
