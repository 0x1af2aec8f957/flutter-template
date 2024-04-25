/// use: https://www.volcengine.com/theme/4075040-R-7-1
/// server: https://github.com/flutter-webrtc/flutter-webrtc-server
/// client: https://github.com/flutter-webrtc/flutter-webrtc
import 'dart:io' show HttpClient, Platform, SecurityContext, WebSocket, X509Certificate;
import 'dart:math' show Random;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../setup/config.dart';
import '../plugins/http.dart';
import '../plugins/dialog.dart';
import '../components/WebRtcScreenSelect.dart';

// url: https://demo.cloudwebrtc.com:8086/api/turn?service=turn&username=flutter-webrtc

final _webrtcUrl = Uri.https('demo.cloudwebrtc.com').replace(scheme: 'wss', path: '/ws', port: 8086);

enum SignalingState {
  ConnectionOpen,
  ConnectionClosed,
  // ConnectionDone,
  ConnectionError,
}

enum CallState {
  CallStateNew,
  CallStateRinging,
  CallStateInvite,
  CallStateConnected,
  CallStateBye,
}

enum VideoSource {
  Camera,
  Screen,
}

class Session {
  Session({required this.sid, required this.pid});
  String pid;
  String sid;
  RTCPeerConnection? pc;
  RTCDataChannel? dc;
  List<RTCIceCandidate> remoteCandidates = [];
}

class Webrtc {
  WebSocket? socket;

  bool get isSignalingConnected => socket?.readyState == 1; // 信令是否已连接（socket 连接即为信令连接）
  late String _selfId;
  final String _sdpSemantics = 'unified-plan';
  final Map<String, Session> _sessions = {};
  MediaStream? _localStream;
  final List<MediaStream> _remoteStreams = <MediaStream>[];
  final List<RTCRtpSender> _senders = <RTCRtpSender>[];
  VideoSource _videoSource = VideoSource.Camera;

  final Function(SignalingState state)? onSignalingStateChange;
  final Function(Session session, CallState state)? onCallStateChange;
  final Function(MediaStream stream)? onLocalStream;
  final Function(Session session, MediaStream stream)? onAddRemoteStream;
  final Function(Session session, MediaStream stream)? onRemoveRemoteStream;
  final Function(dynamic event)? onPeersUpdate;
  final Function(Session session, RTCDataChannel dc, RTCDataChannelMessage data)? onDataChannelMessage;
  final Function(Session session, RTCDataChannel dc)? onDataChannel;

  final Map<String, dynamic> _turnCredential = Map(); // turn 服务器配置

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  /* final Map<String, dynamic> _dcConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': false,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  }; */

  /* final Map<String, dynamic> mediaConstraints = {
      'audio': userScreen ? false : true,
      'video': userScreen
          ? media == 'video'
          : {
              'mandatory': {
                'minWidth': '640', // Provide your own width, height and frame rate here
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
  }; */

  Map<String, dynamic> _getDcConstraintsByMedia(String media) {
    if (media == 'data') {
      return {
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
      };
    }

    return {
      'mandatory': {
        'OfferToReceiveAudio': true, // media == audio,
        'OfferToReceiveVideo': media == 'video',
      },
      'optional': [],
    };
  }

  Map<String, dynamic> _getMediaConstraints(String media, bool userScreen) {
    return {
      'audio': userScreen ? false : true,
      'video': userScreen
          ? media == 'video'
          : {
              'mandatory': {
                'minWidth': '640', // Provide your own width, height and frame rate here
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
    };
  }

  get _iceServerConfig => {
    'iceServers': [
      // {'url': 'stun:stun.l.google.com:19302'},
      /*
        * turn server configuration example.
        { // 遇到 移动网络 无法建立 p2p 连接时，可以尝试使用 turn 服务器：https://github.com/flutter-webrtc/flutter-webrtc-server/issues/59#issuecomment-988560735
          'url': 'turn:123.45.67.89:19302',
          'username': 'change_to_real_user',
          'credential': 'change_to_real_secret'
        },
      */
      {
        'urls': _turnCredential['uris'][0],
        'username': _turnCredential['username'],
        'credential': _turnCredential['password'],
      },
    ],
    // iceTransportPolicy: "relay",
  };

  // Webrtc._internal() {
  Webrtc(String? selfId, {
    this.onSignalingStateChange,
    this.onCallStateChange,
    this.onLocalStream,
    this.onAddRemoteStream,
    this.onRemoveRemoteStream,
    this.onPeersUpdate,
    this.onDataChannelMessage,
    this.onDataChannel,
  }): _selfId = selfId ?? randomNumeric(6) {

    WebSocket.connect(_webrtcUrl.toString(), headers: { // 连接信令服务器
      "Sec-WebSocket-Version": "13",
      "Sec-WebSocket-Key": base64.encode(List<int>.generate(8, (_) => Random().nextInt(255))),
    }, customClient: !AppConfig.isProduction ? (HttpClient(context: SecurityContext())..badCertificateCallback = (X509Certificate cert, String host, int port) {
        Talk.log('SimpleWebSocket: Allow self-signed certificate => $host:$port.', name: 'Webrtc');
        return true;
    }) : null, protocols: ['signaling']).then((_socket) {
      Talk.log('Connected', name: 'Webrtc');
      socket = _socket..listen(onMessage, onDone: onDone, onError: onError);
      onOpen();
    }).onError((error, stackTrace) {
      Talk.log('Connect error: $error', name: 'Webrtc');
      onSignalingStateChange?.call(SignalingState.ConnectionError);
    });

    Http.original.getUri(_webrtcUrl.replace(scheme: 'https', path: '/api/turn', queryParameters: { // 获取 turn 服务器配置
      "service": "turn",
      "username": "flutter-${AppConfig.system}-webrtc"
    })).then((response) {
      /*{
          "username": "1584195784:mbzrxpgjys",
          "password": "isyl6FF6nqMTB9/ig5MrMRUXqZg",
          "ttl": 86400,
          "uris": ["turn:127.0.0.1:19302?transport=udp"]
        }
      */
      if (!AppConfig.isProduction) Talk.log('turn 服务器配置:\n${response.data}', name: 'Webrtc');
      _turnCredential..clear()..addAll(response.data);
    });
  }

  // factory Webrtc() => _instance;
  // static late final Webrtc _instance = Webrtc._internal();

  void onOpen() {
    onSignalingStateChange?.call(SignalingState.ConnectionOpen);
    Talk.log('Open', name: 'Webrtc');
    _send('new', {
      'name': 'Flutter${Platform.operatingSystem}(${Platform.localHostname})',
      'id': _selfId,
      'user_agent': 'flutter-webrtc/${Platform.operatingSystem}-plugin 0.0.1'
    });
  }

  void onDone() {
    Talk.log('Closed by server [${socket?.closeCode} => ${socket?.closeReason}]!', name: 'Webrtc');
    onSignalingStateChange?.call(SignalingState.ConnectionClosed);
    // Talk.log('Socket Don', name: 'Webrtc');
    // onSignalingStateChange?.call(SignalingState.ConnectionDone);
  }

  void onError(error) {
    // onClose?.call(500, error.toString());
    Talk.log('SClosed by server [${socket?.closeCode} => ${socket?.closeReason}', name: 'Webrtc');
    onSignalingStateChange?.call(SignalingState.ConnectionClosed);
  }

  void switchCamera() {
    if(_localStream == null) return;
    if (_videoSource != VideoSource.Camera) {
      _senders.forEach((sender) {
        if (sender.track?.kind == 'video') {
          sender.replaceTrack(_localStream!.getVideoTracks().first);
        }
      });
      _videoSource = VideoSource.Camera;
      onLocalStream?.call(_localStream!);
      return;
    }

    Helper.switchCamera(_localStream!.getVideoTracks().first);
  }

  void switchToScreenSharing(MediaStream stream) {
    if (_localStream == null || _videoSource == VideoSource.Screen) return;
    
    _senders.forEach((sender) {
      if (sender.track!.kind == 'video') {
        sender.replaceTrack(stream.getVideoTracks()[0]);
      }
    });

    onLocalStream?.call(stream);
    _videoSource = VideoSource.Screen;
  }

  void muteMic() { // 关闭｜打开 麦克风
    if (_localStream == null) return;

    final bool enabled = _localStream!.getAudioTracks()[0].enabled;
    _localStream!.getAudioTracks()[0].enabled = !enabled;
  }

  void closeCamera() { // 关闭｜打开 摄像头
    if (_localStream == null) return;

    final bool enabled = _localStream!.getVideoTracks()[0].enabled;
    _localStream!.getVideoTracks()[0].enabled = !enabled;
  }

  Future<void> invite(String peerId, String media, bool useScreen) {
    final sessionId = '${_selfId}-${peerId}';

    return _createSession(
      null,
      peerId: peerId,
      sessionId: sessionId,
      media: media,
      screenSharing: useScreen
    ).then((Session session) {
      _sessions[sessionId] = session;
      if (media == 'data') {
        _createDataChannel(session);
      }
      _createOffer(session, media);
      onCallStateChange?.call(session, CallState.CallStateNew);
      onCallStateChange?.call(session, CallState.CallStateInvite);
    });
  }

  void bye(String sessionId) {
    _send('bye', {
      'session_id': sessionId,
      'from': _selfId,
    });

    _closeSession(sessionId);
  }

  void accept(String sessionId, String media) {
    final session = _sessions[sessionId];

    if (session == null) return;
    _createAnswer(session, media);
  }

  void reject(String sessionId, [BuildContext? context]) {
    final session = _sessions[sessionId];

    if (session == null) return;
    bye(session.sid);
  }

  void onMessage(message) async {
    Talk.log('收到消息：$message', name: 'Webrtc');
    Map<String, dynamic> mapData = json.decode(message);
    final data = mapData['data'];

    switch (mapData['type']) {
      case 'peers':
        {
          List<dynamic> peers = data;
          if (onPeersUpdate != null) {
            final Map<String, dynamic> event = Map<String, dynamic>();
            event['self'] = _selfId;
            event['peers'] = peers;
            onPeersUpdate?.call(event);
          }
        }
        break;
      case 'offer':
        {
          final peerId = data['from'];
          final description = data['description'];
          final media = data['media'];
          final sessionId = data['session_id'];
          final session = _sessions[sessionId];
          final newSession = await _createSession(session,
            peerId: peerId,
            sessionId: sessionId,
            media: media,
            screenSharing: false,
          );
          _sessions[sessionId] = newSession;
          await newSession.pc?.setRemoteDescription(RTCSessionDescription(description['sdp'], description['type']));
          // await _createAnswer(newSession, media);

          if (newSession.remoteCandidates.length > 0) {
            newSession.remoteCandidates.forEach((candidate) async {
              await newSession.pc?.addCandidate(candidate);
            });
            newSession.remoteCandidates.clear();
          }
          onCallStateChange?.call(newSession, CallState.CallStateNew);
          onCallStateChange?.call(newSession, CallState.CallStateRinging);
        }
        break;
      case 'answer':
        {
          final description = data['description'];
          final sessionId = data['session_id'];
          final session = _sessions[sessionId];
          session?.pc?.setRemoteDescription(RTCSessionDescription(description['sdp'], description['type']));
          onCallStateChange?.call(session!, CallState.CallStateConnected);
        }
        break;
      case 'candidate':
        {
          final peerId = data['from'];
          final candidateMap = data['candidate'];
          final sessionId = data['session_id'];
          final session = _sessions[sessionId];
          final RTCIceCandidate candidate = RTCIceCandidate(candidateMap['candidate'], candidateMap['sdpMid'], candidateMap['sdpMLineIndex']);

          if (session == null) {
            _sessions[sessionId] = Session(pid: peerId, sid: sessionId)..remoteCandidates.add(candidate);
            return;
          }

          if (session.pc != null) {
            await session.pc?.addCandidate(candidate);
            return;
          }

          session.remoteCandidates.add(candidate);
        }
        break;
      case 'leave':
        {
          final peerId = data as String;
          _closeSessionByPeerId(peerId);
        }
        break;
      case 'bye':
        {
          final sessionId = data['session_id'];
          Talk.log('bye: $sessionId', name: 'Webrtc');
          _closeSession(sessionId);
        }
        break;
      case 'keepalive':
        {
          Talk.log('keepalive response!', name: 'Webrtc');
        }
        break;
      default:
        break;
    }
  }

  Future<MediaStream> createStream(String media, bool userScreen) async {
    late MediaStream stream;
    final Map<String, dynamic> mediaConstraints = _getMediaConstraints(media, userScreen);

    if (userScreen) {
      if (WebRTC.platformIsDesktop) {
        final source = await showDialog<DesktopCapturerSource>(
          context: AppConfig.navigatorContext,
          builder: (context) => WebRtcScreenSelect(),
        );
        stream = await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
          'video': source == null
              ? true
              : {
                  'deviceId': {'exact': source.id},
                  'mandatory': {'frameRate': 30.0}
                }
        });
      } else {
        stream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      }
    } else {
      stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    }

    onLocalStream?.call(stream);
    return stream;
  }

  Future<Session> _createSession(
    Session? session, {
    required String peerId,
    required String sessionId,
    required String media,
    required bool screenSharing,
  }) async {
    final newSession = session ?? Session(sid: sessionId, pid: peerId);
    if (media != 'data') _localStream = await createStream(media, screenSharing);
    Talk.log('_iceServerConfig: $_iceServerConfig', name: 'Webrtc');
    RTCPeerConnection pc = await createPeerConnection({
      ..._iceServerConfig,
      ...{'sdpSemantics': _sdpSemantics}
    }, _config);
    if (media != 'data') {
      switch (_sdpSemantics) {
        case 'plan-b':
          pc.onAddStream = (MediaStream stream) {
            onAddRemoteStream?.call(newSession, stream);
            _remoteStreams.add(stream);
          };
          await pc.addStream(_localStream!);
          break;
        case 'unified-plan':
          // Unified-Plan
          pc.onTrack = (event) {
            if (['audio', 'video'].contains(event.track.kind)) {
              onAddRemoteStream?.call(newSession, event.streams[0]);
            }
          };
          _localStream!.getTracks().forEach((track) async {
            _senders.add(await pc.addTrack(track, _localStream!));
          });
          break;
      }

      // Unified-Plan: Simuclast
      /*
      await pc.addTransceiver(
        track: _localStream.getAudioTracks()[0],
        init: RTCRtpTransceiverInit(
            direction: TransceiverDirection.SendOnly, streams: [_localStream]),
      );

      await pc.addTransceiver(
        track: _localStream.getVideoTracks()[0],
        init: RTCRtpTransceiverInit(
            direction: TransceiverDirection.SendOnly,
            streams: [
              _localStream
            ],
            sendEncodings: [
              RTCRtpEncoding(rid: 'f', active: true),
              RTCRtpEncoding(
                rid: 'h',
                active: true,
                scaleResolutionDownBy: 2.0,
                maxBitrate: 150000,
              ),
              RTCRtpEncoding(
                rid: 'q',
                active: true,
                scaleResolutionDownBy: 4.0,
                maxBitrate: 100000,
              ),
            ]),
      );*/
      /*
        var sender = pc.getSenders().find(s => s.track.kind == "video");
        var parameters = sender.getParameters();
        if(!parameters) {
          parameters = {};
          parameters.encodings = [
            { rid: "h", active: true, maxBitrate: 900000 },
            { rid: "m", active: true, maxBitrate: 300000, scaleResolutionDownBy: 2 },
            { rid: "l", active: true, maxBitrate: 100000, scaleResolutionDownBy: 4 }
          ];
          sender.setParameters(parameters);
        }
      */
    }
    pc.onIceCandidate = (candidate) async {
      if (candidate == null) {
        Talk.log('onIceCandidate: complete!', name: 'Webrtc');
        return;
      }
      // This delay is needed to allow enough time to try an ICE candidate
      // before skipping to the next one. 1 second is just an heuristic value
      // and should be thoroughly tested in your own environment.
      return Future.delayed(
        const Duration(seconds: 1),
        () => _send('candidate', {
          'to': peerId,
          'from': _selfId,
          'candidate': {
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'sdpMid': candidate.sdpMid,
            'candidate': candidate.candidate,
          },
          'session_id': sessionId,
        }));
    };

    pc.onIceConnectionState = (state) {};

    pc.onRemoveStream = (stream) {
      onRemoveRemoteStream?.call(newSession, stream);
      _remoteStreams.removeWhere((it) {
        return (it.id == stream.id);
      });
    };

    pc.onDataChannel = (channel) {
      _addDataChannel(newSession, channel);
    };

    newSession.pc = pc;
    return newSession;
  }

  void _addDataChannel(Session session, RTCDataChannel channel) {
    channel.onDataChannelState = (e) {};
    channel.onMessage = (RTCDataChannelMessage data) {
      onDataChannelMessage?.call(session, channel, data);
    };
    session.dc = channel;
    onDataChannel?.call(session, channel);
  }

  Future<void> _createDataChannel(Session session, {label = 'fileTransfer'}) async {
    RTCDataChannelInit dataChannelDict = RTCDataChannelInit()..maxRetransmits = 30;
    RTCDataChannel channel = await session.pc!.createDataChannel(label, dataChannelDict);
    _addDataChannel(session, channel);
  }

  Future<void> _createOffer(Session session, String media) async {
    try {
      RTCSessionDescription s = await session.pc!.createOffer(_getDcConstraintsByMedia(media));
      await session.pc!.setLocalDescription(_fixSdp(s));
      _send('offer', {
        'to': session.pid,
        'from': _selfId,
        'description': {'sdp': s.sdp, 'type': s.type},
        'session_id': session.sid,
        'media': media,
      });
    } catch (e) {
      Talk.log('_CreateOffer error: $e', name: 'Webrtc');
    }
  }

  RTCSessionDescription _fixSdp(RTCSessionDescription s) {
    final sdp = s.sdp;
    s.sdp = sdp!.replaceAll('profile-level-id=640c1f', 'profile-level-id=42e032');
    return s;
  }

  Future<void> _createAnswer(Session session, String media) async {
    try {
      final RTCSessionDescription s = await session.pc!.createAnswer(_getDcConstraintsByMedia(media));
      await session.pc!.setLocalDescription(_fixSdp(s));
      _send('answer', {
        'to': session.pid,
        'from': _selfId,
        'description': {'sdp': s.sdp, 'type': s.type},
        'session_id': session.sid,
      });
    } catch (e) {
      Talk.log('_CreateAnswer error: $e', name: 'Webrtc');
    }
  }

  void _send(event, data) {
    Talk.log('发送数据: $data', name: 'Webrtc');
    return socket?.add(jsonEncode({
      "type": event,
      "data": data,
    }));
  }

  Future<void> close() {
    return _cleanSessions().then((_) => socket?.close());
  }

  Future<void> _cleanSessions() async {
    if (_localStream != null) _localStream!
      ..getTracks().forEach((track) => track.stop())
      ..dispose().then((_) { 
        _localStream = null;
      });

    _sessions
      ..forEach((key, sess) async {
        await sess.pc?.close();
        await sess.dc?.close();
      })
      ..clear();
  }

  void _closeSessionByPeerId(String peerId) { // leave
    final sessionId = _sessions.values.firstWhere((_session) => _session.pid == peerId).sid;
    _closeSession(sessionId);
  }

  Future<void> _closeSession(String sessionId) async {
    final session = _sessions.remove(sessionId);
    if (session == null) return;

    _localStream?.getTracks().forEach((element) async {
      await element.stop();
    });
    await _localStream?.dispose();
    _localStream = null;

    await session.pc?.close();
    await session.dc?.close();
    _senders.clear();
    _videoSource = VideoSource.Camera;

    onCallStateChange?.call(session, CallState.CallStateBye);
  }

}