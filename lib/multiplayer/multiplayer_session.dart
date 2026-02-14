import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

import '../game/types.dart';

const int kProtocolVersion = 1;

enum ProtocolType { start, move, rematch, reject, ping }

class ProtocolMessage {
  ProtocolMessage(this.type, this.data);
  final ProtocolType type;
  final Map<String, dynamic> data;
}

class ProtocolDecodeResult {
  ProtocolDecodeResult({this.message, this.error});
  final ProtocolMessage? message;
  final String? error;
}

class StartPayload {
  StartPayload({required this.boardSize, required this.hostIsP1, required this.sessionId});
  final int boardSize;
  final bool hostIsP1;
  final String sessionId;
}

enum RematchAction { request, accept, decline }

class RematchEvent {
  const RematchEvent(this.action);
  final RematchAction action;
}

class MultiplayerProtocol {
  static Uint8List encode(ProtocolType type, Map<String, dynamic> data) {
    final map = {'v': kProtocolVersion, 'type': type.name, 'data': data};
    return Uint8List.fromList(utf8.encode(jsonEncode(map)));
  }

  static Uint8List encodeStart({required int boardSize, required bool hostIsP1, required String sessionId}) {
    return encode(ProtocolType.start, {'boardSize': boardSize, 'hostIsP1': hostIsP1, 'sid': sessionId});
  }

  static Uint8List encodeMove({required String sessionId, required Move move}) {
    return encode(ProtocolType.move, {'sid': sessionId, 'move': MoveCodec.toJson(move)});
  }

  static Uint8List encodeRematch({required String sessionId, required RematchAction action}) {
    return encode(ProtocolType.rematch, {'sid': sessionId, 'action': action.name});
  }

  static Uint8List encodeReject({required String sessionId, required String reason}) {
    return encode(ProtocolType.reject, {'sid': sessionId, 'reason': reason});
  }

  static ProtocolDecodeResult decodePayload(Payload payload) {
    if (payload.type != PayloadType.BYTES) {
      return ProtocolDecodeResult(error: 'Unsupported payload');
    }
    final data = payload.bytes;
    if (data == null) {
      return ProtocolDecodeResult(error: 'Empty payload');
    }

    try {
      final raw = jsonDecode(utf8.decode(data));
      if (raw is! Map<String, dynamic>) {
        return ProtocolDecodeResult(error: 'Invalid message format');
      }

      final version = raw['v'];
      if (version is! int || version != kProtocolVersion) {
        return ProtocolDecodeResult(error: 'Protocol mismatch');
      }

      final typeStr = raw['type'];
      final dataMap = raw['data'];
      if (typeStr is! String || dataMap is! Map<String, dynamic>) {
        return ProtocolDecodeResult(error: 'Malformed message');
      }

      ProtocolType? type;
      for (final t in ProtocolType.values) {
        if (t.name == typeStr) {
          type = t;
          break;
        }
      }
      if (type == null) {
        return ProtocolDecodeResult(error: 'Unknown message type');
      }

      return ProtocolDecodeResult(message: ProtocolMessage(type, dataMap));
    } catch (_) {
      return ProtocolDecodeResult(error: 'Unreadable payload');
    }
  }

  static StartPayload? parseStart(ProtocolMessage msg) {
    if (msg.type != ProtocolType.start) return null;
    final boardSize = msg.data['boardSize'];
    final hostIsP1 = msg.data['hostIsP1'];
    final sid = msg.data['sid'];
    if (boardSize is! int || hostIsP1 is! bool || sid is! String) return null;
    if (boardSize != 5 && boardSize != 6) return null;
    if (sid.isEmpty) return null;
    return StartPayload(boardSize: boardSize, hostIsP1: hostIsP1, sessionId: sid);
  }
}

enum MultiplayerEvent { disconnected }

class MultiplayerSession {
  MultiplayerSession({
    required this.endpointId,
    required this.displayName,
    required this.localPlayer,
    required this.boardSize,
    required this.sessionId,
  });

  final String endpointId;
  final String displayName;
  final Player localPlayer;
  final int boardSize;
  final String sessionId;

  final StreamController<Move> _moves = StreamController.broadcast();
  final StreamController<MultiplayerEvent> _events = StreamController.broadcast();
  final StreamController<RematchEvent> _rematch = StreamController.broadcast();
  final StreamController<String> _errors = StreamController.broadcast();

  Stream<Move> get moves => _moves.stream;
  Stream<MultiplayerEvent> get events => _events.stream;
  Stream<RematchEvent> get rematch => _rematch.stream;
  Stream<String> get errors => _errors.stream;

  Future<void> sendMove(Move mv) async {
    final bytes = MultiplayerProtocol.encodeMove(sessionId: sessionId, move: mv);
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  Future<void> sendRematchRequest() async {
    final bytes = MultiplayerProtocol.encodeRematch(sessionId: sessionId, action: RematchAction.request);
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  Future<void> sendRematchResponse(bool accept) async {
    final bytes = MultiplayerProtocol.encodeRematch(
      sessionId: sessionId,
      action: accept ? RematchAction.accept : RematchAction.decline,
    );
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  Future<void> sendReject(String reason) async {
    final bytes = MultiplayerProtocol.encodeReject(sessionId: sessionId, reason: reason);
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  void handlePayload(Payload payload) {
    final result = MultiplayerProtocol.decodePayload(payload);
    if (result.error != null) {
      _errors.add(result.error!);
      return;
    }
    final msg = result.message;
    if (msg == null) return;
    handleMessage(msg);
  }

  void handleMessage(ProtocolMessage msg) {
    final sid = msg.data['sid'];
    if (sid is! String || sid != sessionId) {
      _errors.add('Session mismatch');
      sendReject('session-mismatch');
      return;
    }

    switch (msg.type) {
      case ProtocolType.move:
        final moveMap = msg.data['move'];
        if (moveMap is! Map<String, dynamic>) {
          _errors.add('Invalid move payload');
          sendReject('invalid-move');
          return;
        }
        if (!MoveCodec.validate(moveMap, boardSize)) {
          _errors.add('Illegal move received');
          sendReject('illegal-move');
          return;
        }
        final mv = MoveCodec.fromJson(moveMap);
        _moves.add(mv);
        break;
      case ProtocolType.rematch:
        final actionStr = msg.data['action'];
        if (actionStr is! String) {
          _errors.add('Invalid rematch request');
          sendReject('invalid-rematch');
          return;
        }
        final action = RematchAction.values.firstWhere(
          (a) => a.name == actionStr,
          orElse: () => RematchAction.decline,
        );
        _rematch.add(RematchEvent(action));
        break;
      case ProtocolType.reject:
        final reason = msg.data['reason'];
        if (reason is String && reason.isNotEmpty) {
          _errors.add('Peer rejected: $reason');
        } else {
          _errors.add('Peer rejected the message');
        }
        break;
      case ProtocolType.ping:
      case ProtocolType.start:
        break;
    }
  }

  void handleDisconnect() {
    _events.add(MultiplayerEvent.disconnected);
  }

  Future<void> dispose() async {
    await _moves.close();
    await _events.close();
    await _rematch.close();
    await _errors.close();
  }
}

class MoveCodec {
  static Map<String, dynamic> toJson(Move mv) {
    switch (mv.kind) {
      case MoveKind.place:
        return {
          'kind': 'place',
          'r': mv.r,
          'c': mv.c,
        };
      case MoveKind.step:
        return {
          'kind': 'step',
          'fr': mv.fr,
          'fc': mv.fc,
          'tr': mv.tr,
          'tc': mv.tc,
        };
      case MoveKind.capture:
        return {
          'kind': 'capture',
          'r': mv.capR,
          'c': mv.capC,
        };
    }
  }

  static Move fromJson(Map<String, dynamic> map) {
    final kind = map['kind'] as String? ?? '';
    switch (kind) {
      case 'place':
        return Move.place(map['r'] as int, map['c'] as int);
      case 'step':
        return Move.step(map['fr'] as int, map['fc'] as int, map['tr'] as int, map['tc'] as int);
      case 'capture':
        return Move.capture(map['r'] as int, map['c'] as int);
      default:
        return Move.place(0, 0);
    }
  }

  static bool validate(Map<String, dynamic> map, int size) {
    final kind = map['kind'];
    if (kind is! String) return false;

    bool inBounds(int r, int c) => r >= 0 && c >= 0 && r < size && c < size;

    switch (kind) {
      case 'place':
        final r = map['r'];
        final c = map['c'];
        if (r is! int || c is! int) return false;
        return inBounds(r, c);
      case 'step':
        final fr = map['fr'];
        final fc = map['fc'];
        final tr = map['tr'];
        final tc = map['tc'];
        if (fr is! int || fc is! int || tr is! int || tc is! int) return false;
        return inBounds(fr, fc) && inBounds(tr, tc);
      case 'capture':
        final r = map['r'];
        final c = map['c'];
        if (r is! int || c is! int) return false;
        return inBounds(r, c);
      default:
        return false;
    }
  }
}


