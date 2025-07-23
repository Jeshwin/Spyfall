import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:spyfall/widgets/big_red_button.dart';
import 'package:spyfall/widgets/role_dialog.dart';
import 'package:spyfall/widgets/sticky_note.dart';
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

  // Add stream subscription variables
  StreamSubscription<Player?>? _playerSubscription;
  StreamSubscription<Room?>? _roomSubscription;
  StreamSubscription<Room?>? _hostStatusSubscription;

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
    // Cancel all stream subscriptions
    _playerSubscription?.cancel();
    _roomSubscription?.cancel();
    _hostStatusSubscription?.cancel();

    // Cancel timer
    _gameTimer?.cancel();

    // Clear lifecycle service when leaving game
    AppLifecycleService().clearCurrentPlayer();
    super.dispose();
  }

  void _watchPlayerData() {
    _playerSubscription = PlayerService.watchPlayerById(widget.playerId).listen(
      (playerData) {
        // Check if widget is still mounted before calling setState
        if (!mounted) return;

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
      },
    );
  }

  void _watchRoomChanges() {
    _roomSubscription = RoomService.watchRoom(widget.roomCode).listen((
      roomData,
    ) {
      // Check if widget is still mounted before calling setState
      if (!mounted) return;

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
    _hostStatusSubscription = RoomService.watchRoom(widget.roomCode).listen((
      roomData,
    ) {
      // Check if widget is still mounted before showing dialog
      if (!mounted) return;

      if (roomData != null &&
          roomData.status == RoomStatus.closed &&
          !_isHost &&
          !_showHostLeftDialog) {
        _showHostLeftDialog = true;
        _showHostLeftGameDialog();
      }
    });
  }

  void _initializeTimer(Room roomData) {
    if (!mounted) return;

    setState(() {
      _remainingTime = roomData.settings.discussionTime;
      _isTimerPaused = roomData.settings.startTimerOnGameStart ? false : true;
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Check if widget is still mounted before calling setState
      if (!mounted) {
        timer.cancel();
        return;
      }

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

      if (mounted) {
        setState(() {
          _locations = locations.map((loc) => loc['name'] as String).toList();
        });
      }
    } catch (e) {
      // Handle error silently - locations will remain empty
    }
  }

  void _loadQuestions() async {
    try {
      final questionsYaml = await rootBundle.loadString('assets/questions.yml');
      final yamlData = loadYaml(questionsYaml);
      final List<dynamic> questions = yamlData['questions'];

      if (mounted) {
        setState(() {
          _questions = questions.map((q) => q as String).toList();
          _currentQuestion = _questions.isNotEmpty
              ? _questions[Random().nextInt(_questions.length)]
              : '';
        });
      }
    } catch (e) {
      // Handle error silently - questions will remain empty
    }
  }

  void _refreshQuestion() {
    if (_questions.isNotEmpty && mounted) {
      setState(() {
        _currentQuestion = _questions[Random().nextInt(_questions.length)];
      });
    }
  }

  void _togglePlayerMark(String playerId) {
    if (!mounted) return;

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
        return Theme.of(context).colorScheme.surface;
    }
  }

  void _showTimeUpDialog() {
    if (!mounted) return;

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
    if (player == null || !mounted) return;

    player?.debugPrint();

    showDialog(
      context: context,
      builder: (context) => RoleDialog(
        isSpy: player!.isSpy,
        role: player!.role,
        location: room?.location,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _leaveGame() {
    if (!mounted) return;

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

              // Update room status if no players are in game
              List<Player> players = await PlayerService.getPlayersInGame(
                widget.roomCode,
              );
              bool hasPlayersInGame = players.any(
                (player) => player.status == PlayerStatus.inGame,
              );

              if (!hasPlayersInGame) {
                final room = await RoomService.getRoomByCode(widget.roomCode);
                if (room != null) {
                  await RoomService.updateRoom(
                    room.copyWith(status: RoomStatus.setup),
                  );
                }
              }
              _showGameResultsDialog(() async {
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
              });
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showGameResultsDialog(Future<void> Function() onContinue) async {
    if (!mounted || room?.location == null) {
      await onContinue();
      return;
    }

    try {
      final players = await PlayerService.getPlayersInGame(widget.roomCode);
      final spy = players.firstWhere(
        (player) => player.isSpy,
        orElse: () => Player(
          id: '',
          name: 'Unknown',
          gameId: widget.roomCode,
          isSpy: false,
          isHost: false,
          status: PlayerStatus.notReady,
          joinedAt: Timestamp.now(),
        ),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Game Results'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Location: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: Text(room!.location!)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.userX, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      'Spy: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        spy.name.isNotEmpty ? spy.name : 'Unknown',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await onContinue();
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      await onContinue();
    }
  }

  void _showHostLeftGameDialog() {
    if (!mounted) return;

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
          child: Text(
            'Room: ${widget.roomCode}',
            style: TextStyle(
              fontSize: 24,
              height: 1.125,
              fontFamily: "Geist Mono",
            ),
          ),
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
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  color: const Color(0xFFAAAAAA),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Add this
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        gradient: RadialGradient(
                          colors: [Color(0xFF450A08), Colors.black],
                        ),
                      ),
                      child: Text(
                        _formatTime(_remainingTime),
                        style: TextStyle(
                          fontSize: 45,
                          height: 1.125,
                          fontFamily: "7 Segment",
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isHost) SizedBox(width: 8),
                    if (_isHost)
                      BigRedButton(
                        onPressed: _toggleTimer,
                        icon: _isTimerPaused
                            ? LucideIcons.play
                            : LucideIcons.pause,
                      ),
                  ],
                ),
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
            style: TextStyle(
              fontSize: 28,
              height: 1.3,
              fontFamily: 'Limelight',
            ),
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
                            height: 1.5,
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
            style: TextStyle(
              fontSize: 28,
              height: 1.3,
              fontFamily: 'Limelight',
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildTwoColumnLayout(),
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    // Split locations into two lists for the columns
    final leftColumnItems = <Widget>[];
    final rightColumnItems = <Widget>[];

    for (int i = 0; i < _locations.length; i++) {
      final location = _locations[i];
      final isCurrentLocation =
          location == room?.location && !(player?.isSpy ?? false);
      final isCrossedOut = _crossedOutLocations.contains(location);

      final card = Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: LocationCard(
          location: location,
          isCurrentLocation: isCurrentLocation,
          isCrossedOut: isCrossedOut,
          onTap: () {
            if (mounted) {
              setState(() {
                if (isCrossedOut) {
                  _crossedOutLocations.remove(location);
                } else {
                  _crossedOutLocations.add(location);
                }
              });
            }
          },
        ),
      );

      // Alternate between left and right columns
      if (i % 2 == 0) {
        leftColumnItems.add(card);
      } else {
        rightColumnItems.add(card);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftColumnItems)),
        const SizedBox(width: 8),
        Expanded(child: Column(children: rightColumnItems)),
      ],
    );
  }

  Widget _buildQuestionsWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Sample Question',
          style: TextStyle(fontSize: 28, height: 1.3, fontFamily: 'Limelight'),
        ),
        const SizedBox(height: 32),
        StickyNote(text: _currentQuestion),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _refreshQuestion,
          icon: const Icon(LucideIcons.refreshCw),
          label: const Text('New Question'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFdf8e1d),
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
