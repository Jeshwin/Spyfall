import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/player.dart';
import '../services/player_service.dart';
import '../services/room_service.dart';

class GamePage extends StatefulWidget {
  final String roomCode;
  final String playerId;

  const GamePage({super.key, required this.roomCode, required this.playerId});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Player? player;
  Timer? _gameTimer;
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    _getPlayerData();
    _startGameTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _getPlayerData() async {
    final playerData = await PlayerService.getPlayerById(widget.playerId);
    setState(() {
      player = playerData;
    });
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

  void _showRoleDialog() {
    if (player == null) return;
    final isSpy = player!.isSpy;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSpy ? LucideIcons.userX : LucideIcons.userCheck,
              size: 64,
              color: isSpy
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isSpy ? 'Role: Spy' : 'Role: ${widget.playerId}',
              style: TextStyle(
                color: isSpy
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isSpy)
              Text(
                'Your mission: Blend in and don\'t get caught!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            if (!isSpy) ...[
              const SizedBox(height: 16),
              Text(
                'Location: School', // TODO: Get actual location
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
        title: GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.roomCode));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Room code ${widget.roomCode} copied to clipboard!',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Text('Room: ${widget.roomCode}'),
        ),
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
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.clock,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_remainingTime),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: IconButton(
                      onPressed: null,
                      icon: Icon(LucideIcons.play),
                    ),
                  ),
                ],
              ),

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
                        widget.playerId,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Role Button
              ElevatedButton.icon(
                onPressed: _showRoleDialog,
                icon: const Icon(LucideIcons.eye),
                label: const Text('View Role'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPlayersList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersList() {
    return StreamBuilder<List<Player>>(
      stream: PlayerService.watchPlayersInGame(widget.roomCode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final players = snapshot.data!;

        if (players.isEmpty) {
          return const Center(child: Text('No players in lobby'));
        }

        return SizedBox(
          height: 200,
          child: Scrollbar(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];

                if (player.id == widget.playerId) {
                  return SizedBox();
                }

                return Card.filled(
                  child: ListTile(
                    leading: Icon(
                      player.isHost ? LucideIcons.crown : LucideIcons.user,
                      color: player.isHost
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    title: Text(player.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (player.isReady)
                          Icon(
                            LucideIcons.check,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        if (player.isHost) const Text('HOST'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
