import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:yaml/yaml.dart';

import '../main.dart';
import '../models/player.dart';
import '../models/room.dart';
import '../pages/lobby_page.dart';
import '../services/app_lifecycle_service.dart';
import '../services/player_service.dart';
import '../services/room_service.dart';
import '../widgets/location_card.dart';

enum PlayerMark { none, suspicious, cleared }

class GamePage extends StatefulWidget {
  final String roomCode;
  final String playerId;

  const GamePage({super.key, required this.roomCode, required this.playerId});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Player? player;
  Room? room;
  Timer? _gameTimer;
  int _remainingTime = 0;
  bool _isTimerPaused = false;
  final Map<String, PlayerMark> _playerMarks = {};
  final Set<String> _crossedOutLocations = {};
  List<String> _locations = [];
  List<String> _questions = [];
  String _currentQuestion = '';
  bool _isHost = false;
  bool _showHostLeftDialog = false;

  @override
  void initState() {
    super.initState();
    _watchPlayerData();
    _loadLocations();
    _loadQuestions();
    _watchRoomChanges();
    _watchHostStatus();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    // Clear lifecycle service when leaving game
    AppLifecycleService().clearCurrentPlayer();
    super.dispose();
  }

  void _watchPlayerData() {
    PlayerService.watchPlayerById(widget.playerId).listen((playerData) {
      if (playerData != null) {
        setState(() {
          player = playerData;
          _isHost = playerData.isHost;
        });
        
        // Update lifecycle service with current player info
        AppLifecycleService().setCurrentPlayer(
          playerId: widget.playerId,
          roomCode: widget.roomCode,
          isHost: playerData.isHost,
        );
      }
    });
  }

  void _watchRoomChanges() {
    RoomService.watchRoom(widget.roomCode).listen((roomData) {
      if (roomData != null) {
        setState(() {
          room = roomData;
          _isTimerPaused = roomData.isTimerPaused;
        });

        if (_gameTimer == null) {
          _initializeTimer(roomData);
        }
      }
    });
  }

  void _watchHostStatus() {
    RoomService.watchRoom(widget.roomCode).listen((roomData) {
      if (roomData != null &&
          roomData.status == RoomStatus.closed &&
          mounted &&
          !_isHost &&
          !_showHostLeftDialog) {
        _showHostLeftDialog = true;
        _showHostLeftGameDialog();
      }
    });
  }

  void _initializeTimer(Room roomData) {
    setState(() {
      _remainingTime = roomData.settings.discussionTime;
      _isTimerPaused = roomData.settings.startTimerOnGameStart ? false : true;
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTimerPaused && _remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else if (_remainingTime <= 0) {
        timer.cancel();
        _showTimeUpDialog();
      }
    });
  }

  void _toggleTimer() async {
    if (_isHost) {
      await RoomService.updateTimerState(widget.roomCode, !_isTimerPaused);
    }
  }

  void _loadLocations() async {
    try {
      final locationsYaml = await rootBundle.loadString('assets/locations.yml');
      final yamlData = loadYaml(locationsYaml);
      final List<dynamic> locations = yamlData['locations'];

      setState(() {
        _locations = locations.map((loc) => loc['name'] as String).toList();
      });
    } catch (e) {
      // Handle error silently - locations will remain empty
    }
  }

  void _loadQuestions() async {
    try {
      final questionsYaml = await rootBundle.loadString('assets/questions.yml');
      final yamlData = loadYaml(questionsYaml);
      final List<dynamic> questions = yamlData['questions'];

      setState(() {
        _questions = questions.map((q) => q as String).toList();
        _currentQuestion = _questions.isNotEmpty
            ? _questions[Random().nextInt(_questions.length)]
            : '';
      });
    } catch (e) {
      // Handle error silently - questions will remain empty
    }
  }

  void _refreshQuestion() {
    if (_questions.isNotEmpty) {
      setState(() {
        _currentQuestion = _questions[Random().nextInt(_questions.length)];
      });
    }
  }

  void _togglePlayerMark(String playerId) {
    setState(() {
      final currentMark = _playerMarks[playerId] ?? PlayerMark.none;
      switch (currentMark) {
        case PlayerMark.none:
          _playerMarks[playerId] = PlayerMark.suspicious;
          break;
        case PlayerMark.suspicious:
          _playerMarks[playerId] = PlayerMark.cleared;
          break;
        case PlayerMark.cleared:
          _playerMarks[playerId] = PlayerMark.none;
          break;
      }
    });
  }

  Color _getPlayerMarkColor(PlayerMark mark) {
    switch (mark) {
      case PlayerMark.suspicious:
        return Theme.of(context).colorScheme.error;
      case PlayerMark.cleared:
        return Colors.green;
      case PlayerMark.none:
        return Colors.transparent;
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

    player?.debugPrint();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isSpy ? Colors.red[50] : null,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSpy ? LucideIcons.userX : LucideIcons.userCheck,
              size: 64,
              color: isSpy ? Theme.of(context).colorScheme.error : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              isSpy ? 'Role: Spy' : 'Role: ${player!.role ?? 'Unknown'}',
              style: TextStyle(
                color: isSpy
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSpy
                  ? 'Location: ???'
                  : 'Location: ${room?.location ?? 'Unknown'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
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
            onPressed: () async {
              // Update player status based on whether they are host or not
              if (_isHost) {
                // Host keeps their status as ready when leaving game
                await PlayerService.updatePlayerStatus(
                  widget.playerId,
                  PlayerStatus.ready,
                );
              } else {
                // Non-host players become not ready when leaving game
                await PlayerService.updatePlayerStatus(
                  widget.playerId,
                  PlayerStatus.notReady,
                );
              }

              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context, rootNavigator: true).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => LobbyPage(
                      roomCode: widget.roomCode,
                      isHost: _isHost, // Keep host status
                      userId: widget.playerId,
                      name: player?.name ?? 'Player',
                    ),
                  ),
                );
              }
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showHostLeftGameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Host Left'),
          content: const Text(
            'The host has left the game. You have been kicked out of the game.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const MyHomePage(title: 'Spyfall'),
                  ),
                  (route) => false,
                );
              },
              child: const Text('Back to Home'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: _leaveGame,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Timer Card
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.clock),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_remainingTime),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isHost)
                    Card(
                      child: IconButton(
                        onPressed: _toggleTimer,
                        icon: Icon(
                          _isTimerPaused ? LucideIcons.play : LucideIcons.pause,
                        ),
                      ),
                    ),
                ],
              ),

              // Role Button
              const SizedBox(height: 16),
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
              _buildPlayersGrid(),
              const SizedBox(height: 16),
              _buildLocationsGrid(),
              const SizedBox(height: 16),
              _buildQuestionsWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Players',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Player>>(
          stream: PlayerService.watchPlayersInGame(widget.roomCode),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final players = snapshot.data!.toList();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final mark = _playerMarks[player.id] ?? PlayerMark.none;

                return GestureDetector(
                  onTap: () => _togglePlayerMark(player.id),
                  child: Card(
                    color: _getPlayerMarkColor(mark),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          player.name,
                          style: TextStyle(
                            color: mark == PlayerMark.none
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Locations',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 16 / 9,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _locations.length,
          itemBuilder: (context, index) {
            final location = _locations[index];
            final isCurrentLocation =
                location == room?.location && !(player?.isSpy ?? false);
            final isCrossedOut = _crossedOutLocations.contains(location);

            return LocationCard(
              location: location,
              isCurrentLocation: isCurrentLocation,
              isCrossedOut: isCrossedOut,
              onTap: () {
                setState(() {
                  if (isCrossedOut) {
                    _crossedOutLocations.remove(location);
                  } else {
                    _crossedOutLocations.add(location);
                  }
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuestionsWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Sample Questions',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          color: Color(0xFFf9e2af),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _currentQuestion,
                  style: GoogleFonts.getFont(
                    "Permanent Marker",
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshQuestion,
                  icon: const Icon(LucideIcons.refreshCw),
                  label: const Text('New Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFdf8e1d),
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
