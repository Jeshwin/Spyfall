import 'package:cloud_firestore/cloud_firestore.dart';

enum PlayerStatus { notReady, ready, inGame }

class Player {
  final String id;
  final String gameId;
  final String name;
  final String? role;
  final bool isSpy;
  final bool isHost;
  final PlayerStatus status;
  final String? votedFor;
  final Timestamp joinedAt;

  Player({
    required this.id,
    required this.gameId,
    required this.name,
    this.role,
    required this.isSpy,
    required this.isHost,
    required this.status,
    this.votedFor,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'name': name,
      'role': role,
      'isSpy': isSpy,
      'isHost': isHost,
      'status': status.name,
      'votedFor': votedFor,
      'joinedAt': joinedAt,
    };
  }

  static Player fromJson(Map<String, dynamic> json, String playerId) {
    // Handle backwards compatibility with old isReady field
    PlayerStatus status;
    if (json['status'] != null) {
      status = PlayerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PlayerStatus.notReady,
      );
    } else {
      // Backwards compatibility: convert old isReady boolean to status
      status = (json['isReady'] ?? false) ? PlayerStatus.ready : PlayerStatus.notReady;
    }

    return Player(
      id: playerId,
      gameId: json['gameId'] ?? '',
      name: json['name'] ?? '',
      role: json['role'],
      isSpy: json['isSpy'] ?? false,
      isHost: json['isHost'] ?? false,
      status: status,
      votedFor: json['votedFor'],
      joinedAt: json['joinedAt'] ?? Timestamp.now(),
    );
  }

  Player copyWith({
    String? id,
    String? gameId,
    String? name,
    String? role,
    bool? isSpy,
    bool? isHost,
    PlayerStatus? status,
    String? votedFor,
    Timestamp? joinedAt,
  }) {
    return Player(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      name: name ?? this.name,
      role: role ?? this.role,
      isSpy: isSpy ?? this.isSpy,
      isHost: isHost ?? this.isHost,
      status: status ?? this.status,
      votedFor: votedFor ?? this.votedFor,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  // Convenience getter for backwards compatibility
  bool get isReady => status == PlayerStatus.ready;
}