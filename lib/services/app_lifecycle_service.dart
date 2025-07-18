import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/room.dart';
import 'player_service.dart';
import 'room_service.dart';

class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();

  factory AppLifecycleService() => _instance;

  AppLifecycleService._internal();

  String? _currentPlayerId;
  String? _currentRoomCode;
  bool _isHost = false;
  bool _isInitialized = false;

  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
    }
  }

  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }

  void setCurrentPlayer({
    required String playerId,
    required String roomCode,
    required bool isHost,
  }) {
    _currentPlayerId = playerId;
    _currentRoomCode = roomCode;
    _isHost = isHost;
  }

  void clearCurrentPlayer() {
    _currentPlayerId = null;
    _currentRoomCode = null;
    _isHost = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (kDebugMode) {
      print('AppLifecycleState changed to: $state');
    }

    switch (state) {
      case AppLifecycleState.detached:
        // App is being closed/terminated
        _handleAppClosed();
        break;
      case AppLifecycleState.paused:
        // App goes to background - no action needed for now
        break;
      case AppLifecycleState.resumed:
        // App comes back to foreground - no action needed for now
        break;
      case AppLifecycleState.inactive:
        // App becomes inactive (e.g., incoming call) - no action needed for now
        break;
      case AppLifecycleState.hidden:
        // App is hidden - no action needed for now
        break;
    }
  }

  void _handleAppClosed() async {
    if (_currentPlayerId != null && _currentRoomCode != null) {
      try {
        if (kDebugMode) {
          print(
            'App closed - cleaning up player $_currentPlayerId from room $_currentRoomCode',
          );
        }

        // If the current player is the host, close the room
        if (_isHost) {
          final room = await RoomService.getRoomByCode(_currentRoomCode!);
          if (room != null) {
            await RoomService.updateRoom(
              room.copyWith(status: RoomStatus.closed),
            );
          }
        }

        // Remove the player from the game
        await PlayerService.removePlayer(_currentPlayerId!);
      } catch (e) {
        if (kDebugMode) {
          print('Error during app close cleanup: $e');
        }
      }
    }
  }
}
