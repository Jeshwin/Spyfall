import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/player.dart';
import '../services/player_service.dart';
import '../services/room_service.dart';

class GamePage extends StatefulWidget {
  final String roomCode;
  final String playerName;

  const GamePage({
    super.key,
    required this.roomCode,
    required this.playerName,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool _isRoleRevealed = false;
  String? _currentPlayerId;
  Timer? _gameTimer;
  int _remainingTime = 0;
  
  @override
  void initState() {
    super.initState();
    _findCurrentPlayer();
    _startGameTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _findCurrentPlayer() async {
    final players = await PlayerService.getPlayersInGame(widget.roomCode);
    for (final player in players) {
      if (player.name == widget.playerName) {
        setState(() {
          _currentPlayerId = player.id;
        });
        break;
      }
    }
  }

  void _startGameTimer() async {
    final room = await RoomService.getRoomByCode(widget.roomCode);
    if (room != null) {
      setState(() {
        _remainingTime = room.settings.discussionTime;
      });
      
      _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime > 0) {
          setState(() {
            _remainingTime--;
          });
        } else {
          timer.cancel();
          _showTimeUpDialog();
        }
      });
    }
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content: const Text('Discussion time has ended. Time to vote!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _revealRole() {
    setState(() {
      _isRoleRevealed = true;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _leaveGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Game'),
        content: const Text('Are you sure you want to leave the game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomCode}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: _leaveGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Timer Card
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_remainingTime),
                        style: GoogleFonts.spaceMono(
                          textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Player Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.user,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Player: ${widget.playerName}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Role Card
              if (_currentPlayerId != null)
                StreamBuilder<Player?>(
                  stream: PlayerService.getPlayerById(_currentPlayerId!).asStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    final player = snapshot.data!;
                    final isSpy = player.isSpy;

                    return Card(
                      color: _isRoleRevealed 
                          ? (isSpy 
                              ? Theme.of(context).colorScheme.errorContainer
                              : Theme.of(context).colorScheme.primaryContainer)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              _isRoleRevealed 
                                  ? (isSpy ? LucideIcons.userX : LucideIcons.userCheck)
                                  : LucideIcons.eyeOff,
                              size: 48,
                              color: _isRoleRevealed
                                  ? (isSpy 
                                      ? Theme.of(context).colorScheme.onErrorContainer
                                      : Theme.of(context).colorScheme.onPrimaryContainer)
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isRoleRevealed 
                                  ? (isSpy ? 'You are the SPY!' : 'You are NOT the spy')
                                  : 'Tap to reveal your role',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _isRoleRevealed
                                    ? (isSpy 
                                        ? Theme.of(context).colorScheme.onErrorContainer
                                        : Theme.of(context).colorScheme.onPrimaryContainer)
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_isRoleRevealed && !isSpy) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Your mission: Find the spy!',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Location: School', // TODO: Get actual location
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (_isRoleRevealed && isSpy) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Your mission: Blend in and don\'t get caught!',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (!_isRoleRevealed) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _revealRole,
                                child: const Text('Reveal Role'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),

              // Players List
              Expanded(
                child: StreamBuilder<List<Player>>(
                  stream: PlayerService.watchPlayersInGame(widget.roomCode),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: ${snapshot.error}'),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    final players = snapshot.data!;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Players (${players.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: players.length,
                                itemBuilder: (context, index) {
                                  final player = players[index];
                                  final isCurrentPlayer = player.name == widget.playerName;
                                  
                                  return ListTile(
                                    leading: Icon(
                                      player.isHost ? LucideIcons.crown : LucideIcons.user,
                                      color: player.isHost
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                    title: Text(
                                      player.name,
                                      style: isCurrentPlayer
                                          ? TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            )
                                          : null,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isCurrentPlayer)
                                          Icon(
                                            LucideIcons.star,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        if (player.isHost)
                                          const Text('HOST'),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}