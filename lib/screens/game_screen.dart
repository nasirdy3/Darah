import 'dart:async';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai/ai_config.dart';
import '../ai/ai_player.dart';
import '../audio/audio_manager.dart';
import '../game/config.dart';
import '../game/dara_detector.dart';
import '../game/rules.dart';
import '../game/session.dart';
import '../game/state.dart';
import '../game/types.dart';
import '../multiplayer/multiplayer_session.dart';
import '../progression/levels.dart';
import '../progression/progression.dart';
import '../skins/skins.dart';
import '../state/profile_store.dart';
import '../state/settings_store.dart';
import '../widgets/animated_dots.dart';
import '../widgets/board_painter.dart';
import '../widgets/confetti.dart';
import '../widgets/token_widget.dart';
import 'dart:ui' show ImageFilter;

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.settings,
    required this.profile,
    this.level,
    this.multiplayer,
    this.forceVsAi,
  });

  final SettingsStore settings;
  final ProfileStore profile;
  final LevelDefinition? level;
  final MultiplayerSession? multiplayer;
  final bool? forceVsAi;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const String _timeoutReason = 'Connection timed out';
  static const String _disconnectReason = 'Disconnected from opponent';
  static const String _protocolReason = 'Protocol error';
  late BoardConfig cfg;
  late GameSession session;
  late BoardSkin boardSkin;
  late SeedSkin seedSkin;

  int? selectedCell;
  Set<int> hintCells = {};

  String toast = '';
  bool gameOver = false;
  Player winner = Player.none;

  bool aiThinking = false;
  int? aiFromCell;
  int? aiToCell;
  int? aiCaptureCell;

  bool showPassOverlay = false;
  Player passTo = Player.none;

  int hintsLeft = 5;
  int undosLeft = 5;
  int usedHints = 0;
  int usedUndos = 0;

  int earnedCoins = 0;
  int earnedStars = 0;

  late AnimationController toastCtrl;
  late AnimationController shakeCtrl;
  late AnimationController confettiCtrl;
  late AnimationController pulseCtrl;
  late AnimationController selectionCtrl;
  late AnimationController aiFocusCtrl;

  final audio = AudioManager.instance;

  StreamSubscription<Move>? _netSub;
  StreamSubscription<MultiplayerEvent>? _eventSub;
  StreamSubscription<RematchEvent>? _rematchSub;
  StreamSubscription<String>? _errorSub;
  Timer? _netTimeout;

  bool connectionLost = false;
  String connectionReason = '';
  bool pendingRematch = false;
  bool incomingRematch = false;

  bool get isNetworked => widget.multiplayer != null;

  Player get human =>
      widget.multiplayer?.localPlayer ??
      (widget.settings.playerIsP1 ? Player.p1 : Player.p2);
  Player get aiSide => human.opponent;

  bool get vsAi {
    if (isNetworked) return false;
    if (widget.forceVsAi != null) return widget.forceVsAi!;
    if (widget.level != null) return true;
    return widget.settings.vsAi;
  }

  int get aiLevel => widget.level?.aiLevel ?? widget.settings.aiLevel;
  String get aiTier => widget.level?.aiTier ?? widget.settings.aiTier;

  bool get isHumansTurn {
    if (connectionLost) return false;
    if (isNetworked) {
      return session.gs.turn == human ||
          (session.gs.phase == Phase.capture && session.gs.captureBy == human);
    }
    if (!vsAi) return true;
    return session.gs.turn == human ||
        (session.gs.phase == Phase.capture && session.gs.captureBy == human);
  }

  @override
  void initState() {
    super.initState();
    toastCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 360));
    confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    selectionCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    aiFocusCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    confettiCtrl.addStatusListener((status) {
      if (!mounted) return;
      setState(() {});
    });
    _newGame();
    if (isNetworked) {
      _netSub = widget.multiplayer!.moves.listen((mv) async {
        if (connectionLost && connectionReason == _timeoutReason) {
          setState(() {
            connectionLost = false;
            connectionReason = '';
          });
        }
        await _applyMove(mv, byRemote: true);
      });
      _eventSub = widget.multiplayer!.events.listen((event) {
        if (event == MultiplayerEvent.disconnected) {
          if (!mounted) return;
          _markConnectionIssue(_disconnectReason);
        }
      });
      _rematchSub = widget.multiplayer!.rematch.listen((event) async {
        await _handleRematchEvent(event);
      });
      _errorSub = widget.multiplayer!.errors.listen((msg) async {
        if (!mounted) return;
        _markConnectionIssue(msg.isEmpty ? _protocolReason : msg);
        await _showToast(msg.isEmpty ? _protocolReason : msg);
      });
    }
    _scheduleNetworkTimeout();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAiTurn());
  }

  void _newGame() {
    final size = widget.multiplayer?.boardSize ??
        widget.level?.boardSize ??
        widget.settings.boardSize;
    cfg = BoardConfig(size);
    session = GameSession(cfg: cfg, human: human);
    boardSkin = boardSkinById(widget.profile.equippedBoard);
    seedSkin = seedSkinById(widget.profile.equippedSeed);

    selectedCell = null;
    hintCells = {};
    toast = '';
    gameOver = false;
    winner = Player.none;

    aiThinking = false;
    aiFromCell = null;
    aiToCell = null;
    aiCaptureCell = null;

    showPassOverlay = false;
    passTo = Player.none;

    connectionLost = false;
    connectionReason = '';
    pendingRematch = false;
    incomingRematch = false;

    hintsLeft = 5 + widget.profile.extraHints;
    undosLeft = 5 + widget.profile.extraUndos;
    usedHints = 0;
    usedUndos = 0;

    earnedCoins = 0;
    earnedStars = 0;

    shakeCtrl.reset();
    confettiCtrl.reset();
    selectionCtrl.reset();

    session.reset();
    _scheduleNetworkTimeout();
  }

  Future<void> _showToast(String msg) async {
    setState(() => toast = msg);
    await toastCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await toastCtrl.reverse();
  }

  void _markConnectionIssue(String reason) {
    _netTimeout?.cancel();
    if (!mounted) return;
    setState(() {
      connectionLost = true;
      connectionReason = reason;
    });
  }

  void _scheduleNetworkTimeout() {
    if (!isNetworked) return;
    _netTimeout?.cancel();
    if (gameOver || connectionLost || isHumansTurn) return;
    _netTimeout = Timer(const Duration(seconds: 90), () {
      if (!mounted) return;
      if (!isNetworked || gameOver || connectionLost || isHumansTurn) return;
      _markConnectionIssue(_timeoutReason);
    });
  }

  Future<void> _requestRematch() async {
    if (!isNetworked || pendingRematch) return;
    setState(() => pendingRematch = true);
    await widget.multiplayer?.sendRematchRequest();
    await _showToast('Rematch request sent');
  }

  Future<void> _respondRematch(bool accept) async {
    await widget.multiplayer?.sendRematchResponse(accept);
    if (accept) {
      _startRematch();
    } else {
      await _showToast('Rematch declined');
    }
  }

  Future<void> _handleRematchEvent(RematchEvent event) async {
    if (!mounted) return;
    switch (event.action) {
      case RematchAction.request:
        if (incomingRematch) return;
        setState(() => incomingRematch = true);
        final accept = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Rematch?'),
              content: const Text('Your opponent wants a rematch.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Decline'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Accept'),
                ),
              ],
            );
          },
        );
        if (!mounted) return;
        setState(() => incomingRematch = false);
        if (accept == true) {
          await _respondRematch(true);
        } else {
          await _respondRematch(false);
        }
        break;
      case RematchAction.accept:
        if (pendingRematch) {
          setState(() => pendingRematch = false);
          _startRematch();
          await _showToast('Rematch accepted');
        }
        break;
      case RematchAction.decline:
        if (pendingRematch) {
          setState(() => pendingRematch = false);
          await _showToast('Rematch declined');
        }
        break;
    }
  }

  void _startRematch() {
    setState(() {
      _newGame();
      pendingRematch = false;
      incomingRematch = false;
    });
    _scheduleNetworkTimeout();
  }

  Future<void> _maybeAiTurn() async {
    if (!vsAi || gameOver || aiThinking) return;

    final aiShouldPlay =
        (session.gs.phase == Phase.capture && session.gs.captureBy == aiSide) ||
            (session.gs.phase != Phase.capture && session.gs.turn == aiSide);
    if (!aiShouldPlay) return;

    setState(() => aiThinking = true);
    
    // Safety delay to ensure state is settled
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || gameOver) {
      setState(() => aiThinking = false);
      return;
    }

    final ai = AIPlayer(
      profile: AiProfile(
        tier: AiTierX.fromId(aiTier),
        level: aiLevel,
        playerAggression: widget.profile.playerAggression,
        playerHeat: widget.profile.heatForSize(cfg.size),
        boardSize: cfg.size,
      ),
    );

    final mv = await ai.chooseMove(session.gs.clone(), aiSide);
    if (!mounted || mv == null || gameOver) {
      if (mounted) setState(() => aiThinking = false);
      return;
    }

    await _animateAiMove(mv);
    await _applyMove(mv, byAi: true);

    if (!mounted) return;
    setState(() {
      aiThinking = false;
      aiFromCell = null;
      aiToCell = null;
      aiCaptureCell = null;
    });
  }

  Future<void> _animateAiMove(Move mv) async {
    if (mv.kind == MoveKind.step) {
      final fromIdx = mv.fr! * cfg.size + mv.fc!;
      final toIdx = mv.tr! * cfg.size + mv.tc!;
      setState(() {
        aiFromCell = fromIdx;
        aiToCell = toIdx;
        aiCaptureCell = null;
      });
      await Future.delayed(const Duration(milliseconds: 520));
    } else if (mv.kind == MoveKind.place) {
      final toIdx = mv.r! * cfg.size + mv.c!;
      setState(() {
        aiFromCell = null;
        aiToCell = toIdx;
        aiCaptureCell = null;
      });
      await Future.delayed(const Duration(milliseconds: 460));
    } else if (mv.kind == MoveKind.capture) {
      final capIdx = mv.capR! * cfg.size + mv.capC!;
      setState(() {
        aiFromCell = null;
        aiToCell = null;
        aiCaptureCell = capIdx;
      });
      await Future.delayed(const Duration(milliseconds: 420));
    }
  }

  Set<int> _highlightCells() {
    final n = cfg.size;
    final set = <int>{};

    if (gameOver) return set;

    if (session.gs.phase == Phase.capture) {
      final enemy = session.gs.captureBy.opponent;
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (session.gs.getCell(r, c) == enemy) set.add(r * n + c);
        }
      }
      return set;
    }

    if (session.gs.phase == Phase.placement) {
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (Rules.isLegalPlace(session.gs, r, c)) set.add(r * n + c);
        }
      }
      return set;
    }

    if (selectedCell != null) {
      final r = selectedCell! ~/ n;
      final c = selectedCell! % n;
      const dirs = [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ];
      for (final d in dirs) {
        final tr = r + d[0];
        final tc = c + d[1];
        if (!cfg.inBounds(tr, tc)) continue;
        if (Rules.isLegalStep(session.gs, r, c, tr, tc)) set.add(tr * n + tc);
      }
    }
    return set;
  }

  Set<int> _daraCells() {
    if (session.gs.phase != Phase.capture) return {};
    final lines = DaraDetector.exact3Lines(session.gs, session.gs.captureBy);
    final cells = <int>{};
    for (final line in lines) {
      for (var i = 0; i < 3; i++) {
        final r = line.r + line.dr * i;
        final c = line.c + line.dc * i;
        cells.add(r * cfg.size + c);
      }
    }
    return cells;
  }

  Future<void> _applyMove(Move mv,
      {bool byAi = false, bool byRemote = false}) async {
    if (gameOver) return;

    session.pushSnapshot();

    switch (mv.kind) {
      case MoveKind.place:
        if (!byAi && !byRemote) {
          widget.profile
              .recordPlacement(idx: mv.r! * cfg.size + mv.c!, size: cfg.size);
        }
        Rules.applyPlace(session.gs, mv.r!, mv.c!);
        await audio.playPlace();
        break;
      case MoveKind.step:
        Rules.applyStep(session.gs, mv.fr!, mv.fc!, mv.tr!, mv.tc!);
        if (!byAi && !byRemote) {
          widget.profile
              .recordStepDestination(idx: mv.tr! * cfg.size + mv.tc!, size: cfg.size);
        }
        await audio.playMove();
        break;
      case MoveKind.capture:
        Rules.applyCapture(session.gs, mv.capR!, mv.capC!);
        await audio.playCapture();
        shakeCtrl.forward(from: 0);
        break;
    }

    final byPlayer = byAi ? aiSide : (byRemote ? human.opponent : human);
    session.recordMove(mv, by: byPlayer);

    if (isNetworked && !byRemote) {
      await widget.multiplayer?.sendMove(mv);
    }

    hintCells = {};

    if (session.gs.phase != Phase.movement) {
      selectedCell = null;
    }

    if (Rules.isWin(session.gs)) {
      winner = Rules.winner(session.gs);
      gameOver = true;
      if (winner == human) {
        await audio.playWin();
        confettiCtrl.forward(from: 0);
      } else {
        await audio.playLose();
      }
      await _handleGameOver();
    }

    if (!mounted) return;
    setState(() {});

    if (!gameOver) {
      if (!vsAi && !isNetworked && session.gs.phase != Phase.capture) {
        showPassOverlay = true;
        passTo = session.gs.turn;
      }
    }

    _scheduleNetworkTimeout();
    await _maybeAiTurn();
  }

  Future<void> _handleGameOver() async {
    if (!vsAi && widget.level == null) return;

    final playerWon = winner == human;
    earnedStars = calculateStars(
        win: playerWon, usedHints: usedHints, usedUndos: usedUndos);

    if (playerWon) {
      earnedCoins = coinsForWin(level: widget.level, stars: earnedStars);
      widget.profile.addCoins(earnedCoins);

      if (widget.level != null) {
        widget.profile.setStars(widget.level!.id, earnedStars);
        widget.profile.unlockNextLevel(widget.level!.id);
      }
    }

    widget.profile.recordGame(
      playerWon: playerWon,
      playerCaptures: session.humanCaptures,
      totalMoves: session.totalMoves,
    );

    await widget.profile.save();
  }

  Future<void> _onTapCell(int idx) async {
    if (gameOver || aiThinking || showPassOverlay || connectionLost) return;

    final n = cfg.size;
    final r = idx ~/ n;
    final c = idx % n;

    if (!isHumansTurn) return;

    hintCells = {};

    if (session.gs.phase == Phase.capture) {
      if (!Rules.isLegalCapture(session.gs, r, c)) {
        await _showToast('Select an opponent seed to remove');
        HapticFeedback.lightImpact();
        return;
      }
      HapticFeedback.mediumImpact();
      await _applyMove(Move.capture(r, c), byAi: false);
      return;
    }

    if (session.gs.phase == Phase.placement) {
      if (!Rules.isLegalPlace(session.gs, r, c)) {
        await _showToast('Invalid placement (no 3-in-row in placement)');
        HapticFeedback.lightImpact();
        return;
      }
      HapticFeedback.selectionClick();
      await _applyMove(Move.place(r, c), byAi: false);
      return;
    }

    final cellPlayer = session.gs.getCell(r, c);

    if (selectedCell == null) {
      if (cellPlayer != session.gs.turn) {
        await _showToast('Select one of your seeds');
        return;
      }
      setState(() {
        selectedCell = idx;
      });
      selectionCtrl.forward(from: 0);
      HapticFeedback.selectionClick();
      audio.playSelect();
      return;
    }

    if (selectedCell == idx) {
      setState(() => selectedCell = null);
      HapticFeedback.selectionClick();
      return;
    }

    final fr = selectedCell! ~/ n;
    final fc = selectedCell! % n;
    if (!Rules.isLegalStep(session.gs, fr, fc, r, c)) {
      await _showToast('Illegal move');
      HapticFeedback.lightImpact();
      return;
    }

    // Speculative update for instant feel
    setState(() {
       selectedCell = null;
    });

    await _applyMove(Move.step(fr, fc, r, c), byAi: false);
  }

  Future<void> _useHint() async {
    if (isNetworked) {
      await _showToast('Hints are disabled in multiplayer');
      return;
    }
    if (hintsLeft <= 0) {
      await _showToast('No hints left');
      return;
    }
    if (!isHumansTurn) {
      await _showToast('Wait for your turn');
      return;
    }

    hintsLeft -= 1;
    usedHints += 1;
    if (hintsLeft < 5 && widget.profile.extraHints > 0) {
      widget.profile.extraHints -= 1;
      await widget.profile.save();
    }

    final ai = AIPlayer(
      profile: AiProfile(
        tier: AiTier.pro,
        level: max(30, aiLevel),
        playerAggression: widget.profile.playerAggression,
        playerHeat: widget.profile.heatForSize(cfg.size),
        boardSize: cfg.size,
      ),
    );

    final mv = await ai.chooseMove(session.gs.clone(), human);
    if (mv == null) {
      await _showToast('No hint available');
      return;
    }

    setState(() {
      hintCells = _hintCellsForMove(mv);
    });

    await _showToast('Hint shown');
  }

  Set<int> _hintCellsForMove(Move mv) {
    final set = <int>{};
    if (mv.kind == MoveKind.place) {
      set.add(mv.r! * cfg.size + mv.c!);
    } else if (mv.kind == MoveKind.step) {
      set.add(mv.fr! * cfg.size + mv.fc!);
      set.add(mv.tr! * cfg.size + mv.tc!);
    } else if (mv.kind == MoveKind.capture) {
      set.add(mv.capR! * cfg.size + mv.capC!);
    }
    return set;
  }

  Future<void> _useUndo() async {
    if (isNetworked) {
      await _showToast('Undo is disabled in multiplayer');
      return;
    }
    if (undosLeft <= 0) {
      await _showToast('No undos left');
      return;
    }
    if (!session.canUndo) {
      await _showToast('Nothing to undo');
      return;
    }

    undosLeft -= 1;
    usedUndos += 1;
    if (undosLeft < 5 && widget.profile.extraUndos > 0) {
      widget.profile.extraUndos -= 1;
      await widget.profile.save();
    }

    session.undo();

    if (vsAi && !isHumansTurn && session.canUndo && undosLeft > 0) {
      undosLeft -= 1;
      usedUndos += 1;
      if (undosLeft < 5 && widget.profile.extraUndos > 0) {
        widget.profile.extraUndos -= 1;
        await widget.profile.save();
      }
      session.undo();
    }

    selectedCell = null;
    hintCells = {};
    gameOver = false;
    winner = Player.none;
    aiThinking = false;
    aiFromCell = null;
    aiToCell = null;
    aiCaptureCell = null;
    showPassOverlay = false;

    setState(() {});
  }

  @override
  void dispose() {
    _netSub?.cancel();
    _eventSub?.cancel();
    _rematchSub?.cancel();
    _errorSub?.cancel();
    _netTimeout?.cancel();
    toastCtrl.dispose();
    shakeCtrl.dispose();
    confettiCtrl.dispose();
    pulseCtrl.dispose();
    selectionCtrl.dispose();
    aiFocusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = cfg.size;
    final legalHighlights = _highlightCells();
    final daraCells = _daraCells();
    final animation = Listenable.merge([pulseCtrl, selectionCtrl, aiFocusCtrl]);

    final phaseLabel = switch (session.gs.phase) {
      Phase.placement => 'Placement',
      Phase.movement => 'Movement',
      Phase.capture => 'Capture',
    };

    final turnLabel = session.gs.phase == Phase.capture
        ? (isNetworked
            ? (session.gs.captureBy == human
                ? 'You formed Dara - capture 1 seed'
                : 'Opponent formed Dara - capture 1 seed')
            : '${_playerName(session.gs.captureBy)} formed Dara - capture 1 seed')
        : (isNetworked
            ? (session.gs.turn == human ? 'Your turn' : "Opponent's turn")
            : '${_playerName(session.gs.turn)} to play');

    final p1Count = session.gs.remainingP1;
    final p2Count = session.gs.remainingP2;

    final titleLabel =
        widget.level != null ? 'Level ${widget.level!.id}' : 'Darah';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isNetworked
                ? null
                : () {
                    setState(() => _newGame());
                    _maybeAiTurn();
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _InfoPill(
                      title: turnLabel,
                      subtitle: 'Phase: $phaseLabel',
                      icon: session.gs.phase == Phase.capture
                          ? Icons.flash_on_rounded
                          : Icons.sports_esports,
                      danger: session.gs.phase == Phase.capture,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                      child: _CountCard(
                          label: 'White',
                          value: p1Count,
                          active: session.gs.turn == Player.p1 ||
                              session.gs.captureBy == Player.p1)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _CountCard(
                          label: 'Black',
                          value: p2Count,
                          active: session.gs.turn == Player.p2 ||
                              session.gs.captureBy == Player.p2)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isNetworked ? null : _useUndo,
                      icon: const Icon(Icons.undo_rounded),
                      label: Text('Undo ($undosLeft)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isNetworked ? null : _useHint,
                      icon: const Icon(Icons.lightbulb_rounded),
                      label: Text('Hint ($hintsLeft)'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side =
                          min(constraints.maxWidth, constraints.maxHeight);
                      final boardSize = Size.square(side);
                      final cell = side / n;
                      final tokenSize = cell * 0.62;

                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) {
                          return Stack(
                            children: [
                              AnimatedBuilder(
                                animation: shakeCtrl,
                                builder: (context, child) {
                                  final shake =
                                      sin(shakeCtrl.value * 2 * pi * 3) *
                                          (1 - shakeCtrl.value) *
                                          6;
                                  return Transform.translate(
                                    offset: Offset(shake, 0),
                                    child: child,
                                  );
                                },
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (d) {
                                    if (!isHumansTurn || aiThinking) return;
                                    final local = d.localPosition;
                                    final hit = hitTestCell(
                                        localPos: local,
                                        boardSize: boardSize,
                                        n: n);
                                    if (hit == null) return;
                                    _onTapCell(hit);
                                  },
                                  child: CustomPaint(
                                    size: boardSize,
                                    painter: BoardPainter(
                                      sizeN: n,
                                      highlightCells: legalHighlights,
                                      hintCells: hintCells,
                                      selectedCell: selectedCell,
                                      captureMode:
                                          session.gs.phase == Phase.capture,
                                      skin: boardSkin,
                                      aiFromCell: aiFromCell,
                                      aiToCell: aiToCell,
                                      aiCaptureCell: aiCaptureCell,
                                      pulse: pulseCtrl.value,
                                    ),
                                  ),
                                ),
                              ),
                              ...List.generate(n * n, (idx) {
                                final r = idx ~/ n;
                                final c = idx % n;
                                final p = session.gs.getCell(r, c);
                                if (p == Player.none)
                                  return const SizedBox.shrink();

                                final left = (c + 0.5) * cell - tokenSize / 2;
                                final top = (r + 0.5) * cell - tokenSize / 2;

                                final glow = daraCells.contains(idx);
                                final selected = selectedCell == idx;
                                final aiSelected =
                                    aiFromCell == idx || aiCaptureCell == idx;
                                final aiPulse = aiFocusCtrl.value;
                                final selectPulse =
                                    selected ? selectionCtrl.value : 0.0;

                                return AnimatedPositioned(
                                  key: ValueKey('t_${idx}_${p.name}'),
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  left: left,
                                  top: top,
                                  width: tokenSize,
                                  height: tokenSize,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 160),
                                    curve: Curves.easeOutBack,
                                    scale: selected
                                        ? (1.06 + 0.04 * selectPulse)
                                        : (aiSelected
                                            ? (1.02 + 0.04 * aiPulse)
                                            : 1.0),
                                    child: TokenWidget(
                                      player: p,
                                      size: tokenSize,
                                      skin: seedSkin,
                                      glow: glow,
                                      selected: selected,
                                      aiSelected: aiSelected,
                                      pulse: selected
                                          ? selectPulse
                                          : (aiSelected ? aiPulse : 0.0),
                                    ),
                                  ),
                                );
                              }),
                              if (aiThinking)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.1),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B1510).withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                                              boxShadow: [
                                                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4DD0E1)),
                                                ),
                                                SizedBox(width: 14),
                                                Text('COMPUTER THINKING',
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 12,
                                                        letterSpacing: 1.2,
                                                        color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (isNetworked &&
                                  !gameOver &&
                                  !connectionLost &&
                                  !isHumansTurn)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B1510)
                                          .withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.hourglass_top_rounded,
                                            size: 16),
                                        SizedBox(width: 6),
                                        Text('Opponent thinking',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        SizedBox(width: 6),
                                        AnimatedDots(size: 5),
                                      ],
                                    ),
                                  ),
                                ),
                              if (gameOver)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.65),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              winner == Player.none
                                                  ? 'Game Over'
                                                  : '${_playerName(winner)} Wins',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w900),
                                            ),
                                            if (earnedStars > 0) ...[
                                              const SizedBox(height: 10),
                                              _Stars(stars: earnedStars),
                                            ],
                                            if (earnedCoins > 0) ...[
                                              const SizedBox(height: 6),
                                              Text('+$earnedCoins coins',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ],
                                            const SizedBox(height: 14),
                                            if (isNetworked)
                                              FilledButton(
                                                onPressed: pendingRematch
                                                    ? null
                                                    : _requestRematch,
                                                child: Text(pendingRematch
                                                    ? 'Rematch requested'
                                                    : 'Rematch'),
                                              )
                                            else
                                              FilledButton(
                                                onPressed: () {
                                                  setState(() => _newGame());
                                                  _maybeAiTurn();
                                                },
                                                child: const Text('Play Again'),
                                              ),
                                            const SizedBox(height: 8),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Exit'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned.fill(
                                child: ConfettiOverlay(
                                    progress: confettiCtrl,
                                    visible: confettiCtrl.isAnimating),
                              ),
                              if (connectionLost && !gameOver)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.75),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.wifi_off_rounded,
                                              size: 42, color: Colors.white),
                                          const SizedBox(height: 10),
                                          Text(
                                            connectionReason.isEmpty
                                                ? 'Connection lost'
                                                : connectionReason,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 6),
                                          const Text('Match paused',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                          const SizedBox(height: 14),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child:
                                                const Text('Return to lobby'),
                                          ),
                                          if (connectionReason ==
                                              _timeoutReason)
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  connectionLost = false;
                                                  connectionReason = '';
                                                });
                                                _scheduleNetworkTimeout();
                                              },
                                              child: const Text('Keep waiting'),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (showPassOverlay && !gameOver && !isNetworked)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => showPassOverlay = false),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                        child: Container(
                                          color: Colors.black.withOpacity(0.6),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.05),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                                  ),
                                                  child: const Icon(Icons.swap_horiz_rounded,
                                                      size: 48, color: Color(0xFF4DD0E1)),
                                                ),
                                                const SizedBox(height: 24),
                                                Text(
                                                  'PASS DEVICE TO ${_playerName(passTo).toUpperCase()}',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 1.5,
                                                      fontSize: 16),
                                                ),
                                                const SizedBox(height: 12),
                                                Text('YOUR TURN NEXT',
                                                    style: TextStyle(
                                                        color: Colors.white.withOpacity(0.5),
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12)),
                                                const SizedBox(height: 40),
                                                Text('TAP ANYWHERE TO START',
                                                    style: TextStyle(
                                                        color: const Color(0xFF4DD0E1).withOpacity(0.8),
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 14,
                                child: FadeTransition(
                                  opacity: CurvedAnimation(
                                      parent: toastCtrl, curve: Curves.easeOut),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF101010)
                                            .withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.10)),
                                      ),
                                      child: Text(toast,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _playerName(Player p) {
    switch (p) {
      case Player.p1:
        return 'White';
      case Player.p2:
        return 'Black';
      case Player.none:
        return 'None';
    }
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(
      {required this.title,
      required this.subtitle,
      required this.icon,
      this.danger = false});
  final String title;
  final String subtitle;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: (danger ? const Color(0xFF5A1D1D) : const Color(0xFF1E1915))
            .withOpacity(0.85),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withOpacity(0.25),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Opacity(
                    opacity: 0.75,
                    child:
                        Text(subtitle, style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard(
      {required this.label, required this.value, required this.active});
  final String label;
  final int value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF15110E).withOpacity(0.88),
        border: Border.all(
            color: active
                ? const Color(0xFFFFD54F).withOpacity(0.25)
                : Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                    opacity: 0.75,
                    child: Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(height: 4),
                Text('$value',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Icon(active ? Icons.circle : Icons.circle_outlined, size: 18),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          color:
              filled ? const Color(0xFFFFD54F) : Colors.white.withOpacity(0.3),
          size: 22,
        );
      }),
    );
  }
}
