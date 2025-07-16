import 'package:cloud_firestore/cloud_firestore.dart';

class Player {
  final String id;
  final String gameId;
  final String name;
  final String? role;
  final bool isSpy;
  final bool isHost;
  final bool isReady;
  final String? votedFor;
  final Timestamp joinedAt;

  Player({
    required this.id,
    required this.gameId,
    required this.name,
    this.role,
    required this.isSpy,
    required this.isHost,
    required this.isReady,
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
      'isReady': isReady,
      'votedFor': votedFor,
      'joinedAt': joinedAt,
    };
  }

  static Player fromJson(Map<String, dynamic> json, String playerId) {
    return Player(
      id: playerId,
      gameId: json['gameId'] ?? '',
      name: json['name'] ?? '',
      role: json['role'],
      isSpy: json['isSpy'] ?? false,
      isHost: json['isHost'] ?? false,
      isReady: json['isReady'] ?? false,
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
    bool? isReady,
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
      isReady: isReady ?? this.isReady,
      votedFor: votedFor ?? this.votedFor,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}