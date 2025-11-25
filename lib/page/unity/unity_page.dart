import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';

class UnityPage extends StatefulWidget {
  final String markerId;
  final String backendBase;

  const UnityPage({
    super.key,
    required this.markerId,
    required this.backendBase,
  });

  @override
  State<UnityPage> createState() => _UnityPageState();
}

class _UnityPageState extends State<UnityPage> {
  bool _sceneReady = false;
  String? _lastMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendMarkerToUnity();
    });
  }

  void _sendMarkerToUnity() {
    if (widget.markerId.isEmpty) return;

    final payload = jsonEncode({
      'markerId': widget.markerId,
      'backendBase': widget.backendBase,
    });

    debugPrint('[Flutter] -> Unity: $payload');

    sendToUnity(
      'FlutterBridge',
      'SetMarkerJson',
      payload,
    );
  }

  void _onUnityMessage(String data) {
    debugPrint('[Flutter] <- Unity: $data');
    setState(() => _lastMessage = data);

    if (data == 'SceneReady') {
      setState(() => _sceneReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleCode =
    widget.markerId.isEmpty ? '(no id)' : widget.markerId;

    return Scaffold(
      appBar: AppBar(
        title: Text('AR — $titleCode'),
        actions: [
          IconButton(
            tooltip: 'Reload marker',
            icon: const Icon(Icons.refresh),
            onPressed: _sceneReady ? _sendMarkerToUnity : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: EmbedUnity(
              onMessageFromUnity: _onUnityMessage,
            ),
          ),
          if (_lastMessage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Unity: $_lastMessage',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
