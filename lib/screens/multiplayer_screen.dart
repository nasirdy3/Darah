import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import '../game/types.dart';
import '../multiplayer/multiplayer_session.dart';
import '../state/profile_store.dart';
import '../state/settings_store.dart';
import 'game_screen.dart';

class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key, required this.settings, required this.profile});
  final SettingsStore settings;
  final ProfileStore profile;

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> with SingleTickerProviderStateMixin {
  final Nearby _nearby = Nearby();
  final String _serviceId = 'com.example.darah.nearby';
  final Strategy _strategy = Strategy.P2P_STAR;

  late TabController _tabs;
  final Map<String, _Endpoint> _endpoints = {};

  bool _hosting = false;
  bool _discovering = false;
  bool _connecting = false;
  String _status = 'Idle';
  String? _connectedId;
  MultiplayerSession? _session;
  int _boardSize = 5;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _boardSize = widget.settings.boardSize;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nearby.stopAdvertising();
    _nearby.stopDiscovery();
    _nearby.stopAllEndpoints();
    _session?.dispose();
    super.dispose();
  }

  Future<bool> _ensurePermissions() async {
    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];

    final statuses = await permissions.request();
    final granted = statuses.values.every((s) => s.isGranted || s.isLimited);
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth and location permissions are required.')),
        );
      }
    }
    return granted;
  }

  Future<void> _startHosting() async {
    if (!await _ensurePermissions()) return;
    setState(() {
      _status = 'Hosting...';
      _hosting = true;
      _discovering = false;
      _connecting = false;
      _endpoints.clear();
    });

    try {
      await _nearby.startAdvertising(
        _deviceName(),
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      _setStatus('Failed to host');
    }
  }

  Future<void> _startDiscovery() async {
    if (!await _ensurePermissions()) return;
    setState(() {
      _status = 'Searching...';
      _discovering = true;
      _hosting = false;
      _connecting = false;
      _endpoints.clear();
    });

    try {
      await _nearby.startDiscovery(
        _deviceName(),
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          if (serviceId != _serviceId) return;
          setState(() {
            _endpoints[id] = _Endpoint(id: id, name: name, serviceId: serviceId);
          });
        },
        onEndpointLost: (id) {
          setState(() => _endpoints.remove(id));
        },
      );
    } catch (e) {
      _setStatus('Discovery failed');
    }
  }

  Future<void> _connectTo(_Endpoint endpoint) async {
    if (!await _ensurePermissions()) return;
    setState(() {
      _connecting = true;
      _status = 'Connecting to ${endpoint.name}...';
    });

    try {
      await _nearby.requestConnection(
        _deviceName(),
        endpoint.id,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      _setStatus('Connection failed');
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    _connectedId = id;
    _nearby.acceptConnection(
      id,
      onPayLoadReceived: (endpointId, payload) {
        _handlePayload(endpointId, payload);
      },
      onPayloadTransferUpdate: (id, update) {},
    );
  }

  void _onConnectionResult(String id, Status status) async {
    if (status == Status.CONNECTED) {
      _setStatus('Connected');
      _connectedId = id;
      if (_hosting) {
        final sessionId = _newSessionId();
        final session = MultiplayerSession(
          endpointId: id,
          displayName: 'Guest',
          localPlayer: Player.p1,
          boardSize: _boardSize,
          sessionId: sessionId,
        );
        _session = session;
        await _sendStartMessage(id, sessionId, _boardSize, hostIsP1: true);
        _openGame(session);
      }
    } else {
      _setStatus('Connection failed');
    }
  }

  void _onDisconnected(String id) {
    _session?.handleDisconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected from peer')),
      );
    }
  }

  Future<void> _sendStartMessage(String endpointId, String sessionId, int size, {required bool hostIsP1}) async {
    final bytes = MultiplayerProtocol.encodeStart(boardSize: size, hostIsP1: hostIsP1, sessionId: sessionId);
    await _nearby.sendBytesPayload(endpointId, bytes);
  }

  void _handlePayload(String endpointId, Payload payload) {
    final result = MultiplayerProtocol.decodePayload(payload);
    if (result.error != null) {
      _setStatus(result.error!);
      if (_session != null) {
        _session!.sendReject(result.error!);
      }
      return;
    }

    final msg = result.message;
    if (msg == null) return;

    if (msg.type == ProtocolType.start && _session == null) {
      final start = MultiplayerProtocol.parseStart(msg);
      if (start == null) {
        _setStatus('Invalid start message');
        return;
      }
      final session = MultiplayerSession(
        endpointId: endpointId,
        displayName: 'Host',
        localPlayer: start.hostIsP1 ? Player.p2 : Player.p1,
        boardSize: start.boardSize,
        sessionId: start.sessionId,
      );
      _session = session;
      _openGame(session);
      return;
    }

    if (_session != null) {
      _session!.handleMessage(msg);
    }
  }

  void _openGame(MultiplayerSession session) {
    _nearby.stopAdvertising();
    _nearby.stopDiscovery();

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => GameScreen(
              settings: widget.settings,
              profile: widget.profile,
              multiplayer: session,
              forceVsAi: false,
            ),
          ),
        )
        .then((_) {
      _cleanupSession();
    });
  }

  void _cleanupSession() {
    _nearby.stopAllEndpoints();
    _session?.dispose();
    _session = null;
    _connectedId = null;
    setState(() {
      _status = 'Idle';
      _hosting = false;
      _discovering = false;
      _connecting = false;
      _endpoints.clear();
    });
  }

  void _setStatus(String status) {
    if (!mounted) return;
    setState(() => _status = status);
  }

  String _deviceName() => 'Darah Player';

  String _newSessionId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Host'),
            Tab(text: 'Join'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildHost(),
          _buildJoin(),
        ],
      ),
    );
  }

  Widget _buildHost() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusCard(status: _status),
        const SizedBox(height: 12),
        _Card(
          title: 'Board Size',
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('5x5'),
                selected: _boardSize == 5,
                onSelected: (v) => setState(() => _boardSize = 5),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('6x6'),
                selected: _boardSize == 6,
                onSelected: (v) => setState(() => _boardSize = 6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _hosting ? null : _startHosting,
          icon: const Icon(Icons.wifi_tethering_rounded),
          label: Text(_hosting ? 'Hosting...' : 'Start Hosting'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _hosting ? _cleanupSession : null,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Stop'),
        ),
      ],
    );
  }

  Widget _buildJoin() {
    final endpoints = _endpoints.values.toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusCard(status: _status),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _discovering ? null : _startDiscovery,
          icon: const Icon(Icons.search_rounded),
          label: Text(_discovering ? 'Searching...' : 'Search for Hosts'),
        ),
        const SizedBox(height: 12),
        ...endpoints.map((e) {
          return _EndpointTile(
            endpoint: e,
            connecting: _connecting,
            onTap: () => _connectTo(e),
          );
        }),
        if (endpoints.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Opacity(
              opacity: 0.6,
              child: Text(
                'No hosts found. Make sure both devices are nearby and permissions are granted.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }
}

class _Endpoint {
  const _Endpoint({required this.id, required this.name, required this.serviceId});
  final String id;
  final String name;
  final String serviceId;
}

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({required this.endpoint, required this.connecting, required this.onTap});
  final _Endpoint endpoint;
  final bool connecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1B1510),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(endpoint.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(endpoint.id, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
          FilledButton(
            onPressed: connecting ? null : onTap,
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF15110E).withOpacity(0.88),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1C1510),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

