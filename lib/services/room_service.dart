import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room.dart';

class RoomService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _roomsCollection = 'rooms';

  static String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  static Future<bool> _isRoomCodeUnique(String roomCode) async {
    final doc = await _firestore
        .collection(_roomsCollection)
        .doc(roomCode)
        .get();
    return !doc.exists;
  }

  static Future<String> _generateUniqueRoomCode() async {
    String roomCode;
    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      roomCode = _generateRoomCode();
      isUnique = await _isRoomCodeUnique(roomCode);
      attempts++;
    } while (!isUnique && attempts < maxAttempts);

    if (!isUnique) {
      throw Exception(
        'Failed to generate unique room code after $maxAttempts attempts',
      );
    }

    return roomCode;
  }

  static Future<Room> createRoom({
    required String createdBy,
    RoomSettings? settings,
  }) async {
    try {
      final roomCode = await _generateUniqueRoomCode();
      final defaultSettings =
          settings ??
          RoomSettings(
            discussionTime: 480, // 8 minutes
            votingTime: 120, // 2 minutes
            startTimerOnGameStart: true,
          );

      final room = Room(
        id: roomCode,
        roomCode: roomCode,
        status: RoomStatus.setup,
        createdAt: Timestamp.now(),
        createdBy: createdBy,
        settings: defaultSettings,
      );

      await _firestore
          .collection(_roomsCollection)
          .doc(roomCode)
          .set(room.toJson());

      return room;
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  static Future<Room?> getRoomByCode(String roomCode) async {
    try {
      final doc = await _firestore
          .collection(_roomsCollection)
          .doc(roomCode)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Room.fromJson(doc.data()!, roomCode);
    } catch (e) {
      throw Exception('Failed to get room: $e');
    }
  }

  static Future<void> updateRoom(Room room) async {
    try {
      await _firestore
          .collection(_roomsCollection)
          .doc(room.roomCode)
          .update(room.toJson());
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  static Future<void> deleteRoom(String roomCode) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomCode).delete();
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }

  static Stream<Room?> watchRoom(String roomCode) {
    return _firestore.collection(_roomsCollection).doc(roomCode).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        return null;
      }
      return Room.fromJson(snapshot.data()!, roomCode);
    });
  }
}
