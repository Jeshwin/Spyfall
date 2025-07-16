import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../models/player.dart';

class PlayerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _playersCollection = 'players';

  /// Creates a new player and joins them to the specified game
  static Future<Player> createPlayer({
    required String gameId,
    required String userId,
    required String name,
    required bool isHost,
  }) async {
    try {
      final player = Player(
        id: userId,
        gameId: gameId,
        name: name,
        isSpy: false,
        isHost: isHost,
        isReady: isHost,
        // Host is automatically ready
        joinedAt: Timestamp.now(),
      );

      await _firestore
          .collection(_playersCollection)
          .doc(userId)
          .set(player.toJson());

      return player;
    } catch (e) {
      throw Exception('Failed to create player: $e');
    }
  }

  /// Updates an existing player
  static Future<void> updatePlayer(Player player) async {
    try {
      await _firestore
          .collection(_playersCollection)
          .doc(player.id)
          .update(player.toJson());
    } catch (e) {
      throw Exception('Failed to update player: $e');
    }
  }

  /// Updates player name only
  static Future<void> updatePlayerName(String playerId, String name) async {
    try {
      await _firestore.collection(_playersCollection).doc(playerId).update({
        'name': name,
      });
    } catch (e) {
      throw Exception('Failed to update player name: $e');
    }
  }

  /// Updates player ready status
  static Future<void> updatePlayerReady(String playerId, bool isReady) async {
    try {
      await _firestore.collection(_playersCollection).doc(playerId).update({
        'isReady': isReady,
      });
    } catch (e) {
      throw Exception('Failed to update player ready status: $e');
    }
  }

  /// Gets all players in a specific game
  static Future<List<Player>> getPlayersInGame(String gameId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_playersCollection)
          .where('gameId', isEqualTo: gameId)
          .orderBy('joinedAt')
          .get();

      return querySnapshot.docs
          .map((doc) => Player.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get players in game: $e');
    }
  }

  /// Stream of all players in a specific game
  static Stream<List<Player>> watchPlayersInGame(String gameId) {
    return _firestore
        .collection(_playersCollection)
        .where('gameId', isEqualTo: gameId)
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Player.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Gets a specific player by ID
  static Future<Player?> getPlayerById(String playerId) async {
    try {
      final doc = await _firestore
          .collection(_playersCollection)
          .doc(playerId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Player.fromJson(doc.data()!, playerId);
    } catch (e) {
      throw Exception('Failed to get player: $e');
    }
  }

  /// Removes a player from the game
  static Future<void> removePlayer(String playerId) async {
    try {
      await _firestore.collection(_playersCollection).doc(playerId).delete();
    } catch (e) {
      throw Exception('Failed to remove player: $e');
    }
  }

  /// Removes all players from a specific game
  static Future<void> removeAllPlayersFromGame(String gameId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_playersCollection)
          .where('gameId', isEqualTo: gameId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove players from game: $e');
    }
  }

  // Assign all players a random role for the selected location
  static Future<void> assignRandomRoles(
    String gameId,
    String selectedLocation,
  ) async {
    try {
      final String locationsYaml = await rootBundle.loadString(
        'assets/locations.yml',
      );
      final yamlData = loadYaml(locationsYaml);
      final List<dynamic> locations = yamlData['locations'];

      // Get selected location
      final foundSelectedLocation = locations.firstWhere(
        (loc) => loc['name'] == selectedLocation,
        orElse: () => null,
      );
      final roles = foundSelectedLocation['roles'];

      if (foundSelectedLocation == null) {
        throw Exception('Location "$foundSelectedLocation" not found');
      }

      final querySnapshot = await _firestore
          .collection(_playersCollection)
          .where('gameId', isEqualTo: gameId)
          .orderBy('joinedAt')
          .get();
      final players = querySnapshot.docs;
      if (players.isEmpty) {
        throw Exception('No players found for game $gameId');
      }

      final random = Random();
      final batch = _firestore.batch();

      // Assign random role to each player
      for (final player in players) {
        final randomRole = roles[random.nextInt(roles.length)];
        batch.update(player.reference, {
          'role': randomRole,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading locations: $e');
      }
      rethrow;
    }
  }

  /// Assigns spy role to a random player in the game
  static Future<String> assignRandomSpy(String gameId) async {
    try {
      final players = await getPlayersInGame(gameId);

      if (players.isEmpty) {
        throw Exception('No players found in game');
      }

      // Select a random player to be the spy
      final random = Random();
      final spyIndex = random.nextInt(players.length);
      final spyPlayer = players[spyIndex];

      // Update all players
      final updateFutures = <Future<void>>[];

      for (int i = 0; i < players.length; i++) {
        final player = players[i];

        if (i == spyIndex) {
          updateFutures.add(
            updatePlayer(player.copyWith(isSpy: true, role: null)),
          );
        } else {
          updateFutures.add(updatePlayer(player.copyWith(isSpy: false)));
        }
      }

      await Future.wait(updateFutures);

      return spyPlayer.id;
    } catch (e) {
      throw Exception('Failed to assign spy: $e');
    }
  }

  /// Checks if all players in a game are ready
  static Future<bool> areAllPlayersReady(String gameId) async {
    try {
      final players = await getPlayersInGame(gameId);

      if (players.isEmpty) {
        return false;
      }

      return players.every((player) => player.isReady);
    } catch (e) {
      throw Exception('Failed to check if all players are ready: $e');
    }
  }
}
