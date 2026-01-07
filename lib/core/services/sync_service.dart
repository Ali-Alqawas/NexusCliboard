import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// NexusClip - خدمة المزامنة مع Linux
/// Linux Sync Service
///
/// تدير المزامنة عبر الشبكة المحلية (LAN) باستخدام UDP
/// Manages LAN sync using UDP protocol
///
/// المواصفات / Specifications:
/// - UDP Socket على Port 4040
/// - كشف تلقائي للأجهزة باستخدام mDNS/Broadcast
/// - إرسال واستقبال النصوص المنسوخة فورياً
/// - لا يتم إرسال أي بيانات للإنترنت
class SyncService {
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // =====================================================
  // ثوابت / Constants
  // =====================================================

  static const int _syncPort = 4040;
  static const String _broadcastAddress = '255.255.255.255';
  static const String _discoveryMessage = 'NEXUSCLIP_DISCOVER';
  static const String _clipboardPrefix = 'NEXUSCLIP_CLIP:';
  static const String _ackPrefix = 'NEXUSCLIP_ACK:';
  static const Duration _discoveryTimeout = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // =====================================================
  // الحالة / State
  // =====================================================

  RawDatagramSocket? _socket;
  Timer? _heartbeatTimer;
  Timer? _discoveryTimer;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // الأجهزة المكتشفة / Discovered devices
  final List<SyncDevice> _discoveredDevices = [];
  List<SyncDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  // جهاز Linux المتصل حالياً
  // Currently connected Linux device
  SyncDevice? _connectedDevice;
  SyncDevice? get connectedDevice => _connectedDevice;

  // =====================================================
  // Callbacks
  // =====================================================

  Function(String content)? onClipboardReceived;
  Function(SyncDevice device)? onDeviceDiscovered;
  Function(SyncDevice device)? onDeviceDisconnected;
  Function(String message)? onError;

  // =====================================================
  // بدء وإيقاف الخدمة / Start & Stop
  // =====================================================

  /// بدء خدمة المزامنة
  /// Start sync service
  Future<bool> start() async {
    if (_isRunning) return true;

    try {
      // إنشاء UDP Socket
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _syncPort,
        reuseAddress: true,
      );

      // تفعيل البث / Enable broadcast
      _socket!.broadcastEnabled = true;

      // الاستماع للرسائل
      _socket!.listen(_handleDatagram);

      _isRunning = true;

      // بدء اكتشاف الأجهزة
      await discoverDevices();

      // بدء Heartbeat
      _startHeartbeat();

      if (kDebugMode) {
        debugPrint('Sync service started on port $_syncPort');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting sync service: $e');
      }
      onError?.call('Failed to start sync: $e');
      return false;
    }
  }

  /// إيقاف خدمة المزامنة
  /// Stop sync service
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _discoveryTimer?.cancel();
    _socket?.close();
    _socket = null;
    _isRunning = false;
    _isConnected = false;
    _connectedDevice = null;
    _discoveredDevices.clear();

    if (kDebugMode) {
      debugPrint('Sync service stopped');
    }
  }

  // =====================================================
  // اكتشاف الأجهزة / Device Discovery
  // =====================================================

  /// اكتشاف الأجهزة على الشبكة
  /// Discover devices on network
  Future<List<SyncDevice>> discoverDevices() async {
    if (!_isRunning || _socket == null) {
      return [];
    }

    _discoveredDevices.clear();

    try {
      // إرسال رسالة الاكتشاف
      final message = utf8.encode(_discoveryMessage);
      _socket!.send(
        message,
        InternetAddress(_broadcastAddress),
        _syncPort,
      );

      // انتظار الردود
      await Future.delayed(_discoveryTimeout);

      if (kDebugMode) {
        debugPrint('Discovered ${_discoveredDevices.length} devices');
      }

      return _discoveredDevices;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error discovering devices: $e');
      }
      return [];
    }
  }

  /// الاتصال بجهاز محدد
  /// Connect to specific device
  Future<bool> connectToDevice(SyncDevice device) async {
    try {
      _connectedDevice = device;
      _isConnected = true;

      // إرسال رسالة تأكيد الاتصال
      _sendAck(device.address, 'CONNECTED');

      if (kDebugMode) {
        debugPrint('Connected to ${device.name} (${device.address})');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error connecting to device: $e');
      }
      return false;
    }
  }

  /// قطع الاتصال
  /// Disconnect from device
  void disconnect() {
    if (_connectedDevice != null) {
      _sendAck(_connectedDevice!.address, 'DISCONNECTED');
      onDeviceDisconnected?.call(_connectedDevice!);
    }
    _connectedDevice = null;
    _isConnected = false;
  }

  // =====================================================
  // إرسال واستقبال الحافظة / Send & Receive Clipboard
  // =====================================================

  /// إرسال نص إلى الجهاز المتصل
  /// Send text to connected device
  Future<bool> sendClipboard(String content) async {
    if (!_isConnected || _connectedDevice == null || _socket == null) {
      return false;
    }

    try {
      final message = '$_clipboardPrefix${base64Encode(utf8.encode(content))}';
      final data = utf8.encode(message);

      _socket!.send(
        data,
        InternetAddress(_connectedDevice!.address),
        _syncPort,
      );

      if (kDebugMode) {
        debugPrint('Clipboard sent to ${_connectedDevice!.name}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending clipboard: $e');
      }
      onError?.call('Failed to send clipboard: $e');
      return false;
    }
  }

  /// بث نص لجميع الأجهزة
  /// Broadcast text to all devices
  Future<void> broadcastClipboard(String content) async {
    if (!_isRunning || _socket == null) return;

    try {
      final message = '$_clipboardPrefix${base64Encode(utf8.encode(content))}';
      final data = utf8.encode(message);

      _socket!.send(
        data,
        InternetAddress(_broadcastAddress),
        _syncPort,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error broadcasting clipboard: $e');
      }
    }
  }

  // =====================================================
  // معالجة الرسائل / Message Handling
  // =====================================================

  void _handleDatagram(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    final datagram = _socket?.receive();
    if (datagram == null) return;

    final message = utf8.decode(datagram.data);
    final senderAddress = datagram.address.address;

    _processMessage(message, senderAddress);
  }

  void _processMessage(String message, String senderAddress) {
    // رسالة اكتشاف
    if (message == _discoveryMessage) {
      _handleDiscoveryRequest(senderAddress);
      return;
    }

    // رد على الاكتشاف
    if (message.startsWith('NEXUSCLIP_DEVICE:')) {
      _handleDiscoveryResponse(message, senderAddress);
      return;
    }

    // محتوى حافظة
    if (message.startsWith(_clipboardPrefix)) {
      _handleClipboardMessage(message, senderAddress);
      return;
    }

    // تأكيد
    if (message.startsWith(_ackPrefix)) {
      _handleAck(message, senderAddress);
      return;
    }

    // Heartbeat
    if (message == 'NEXUSCLIP_HEARTBEAT') {
      _handleHeartbeat(senderAddress);
      return;
    }
  }

  void _handleDiscoveryRequest(String senderAddress) {
    // الرد على طلب الاكتشاف
    final deviceInfo = 'NEXUSCLIP_DEVICE:Android|${_getDeviceName()}';
    final data = utf8.encode(deviceInfo);

    _socket?.send(
      data,
      InternetAddress(senderAddress),
      _syncPort,
    );
  }

  void _handleDiscoveryResponse(String message, String senderAddress) {
    try {
      final parts = message.substring('NEXUSCLIP_DEVICE:'.length).split('|');
      if (parts.length >= 2) {
        final device = SyncDevice(
          address: senderAddress,
          platform: parts[0],
          name: parts[1],
          lastSeen: DateTime.now(),
        );

        // تحقق من عدم التكرار
        final existing = _discoveredDevices.indexWhere(
          (d) => d.address == senderAddress,
        );

        if (existing >= 0) {
          _discoveredDevices[existing] = device;
        } else {
          _discoveredDevices.add(device);
          onDeviceDiscovered?.call(device);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing device response: $e');
      }
    }
  }

  void _handleClipboardMessage(String message, String senderAddress) {
    try {
      final base64Content = message.substring(_clipboardPrefix.length);
      final content = utf8.decode(base64Decode(base64Content));

      // إرسال تأكيد
      _sendAck(senderAddress, 'RECEIVED');

      // إشعار المستمع
      onClipboardReceived?.call(content);

      if (kDebugMode) {
        debugPrint('Received clipboard from $senderAddress');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing clipboard message: $e');
      }
    }
  }

  void _handleAck(String message, String senderAddress) {
    final ackType = message.substring(_ackPrefix.length);
    if (kDebugMode) {
      debugPrint('Received ACK: $ackType from $senderAddress');
    }
  }

  void _handleHeartbeat(String senderAddress) {
    // تحديث آخر ظهور للجهاز
    final index = _discoveredDevices.indexWhere(
      (d) => d.address == senderAddress,
    );

    if (index >= 0) {
      _discoveredDevices[index] = _discoveredDevices[index].copyWith(
        lastSeen: DateTime.now(),
      );
    }
  }

  void _sendAck(String address, String ackType) {
    final message = '$_ackPrefix$ackType';
    final data = utf8.encode(message);

    _socket?.send(
      data,
      InternetAddress(address),
      _syncPort,
    );
  }

  // =====================================================
  // Heartbeat
  // =====================================================

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendHeartbeat();
      _cleanupStaleDevices();
    });
  }

  void _sendHeartbeat() {
    if (!_isRunning || _socket == null) return;

    final data = utf8.encode('NEXUSCLIP_HEARTBEAT');
    _socket!.send(
      data,
      InternetAddress(_broadcastAddress),
      _syncPort,
    );
  }

  void _cleanupStaleDevices() {
    final now = DateTime.now();
    final staleTimeout = Duration(minutes: 2);

    _discoveredDevices.removeWhere((device) {
      final isStale = now.difference(device.lastSeen) > staleTimeout;
      if (isStale && device.address == _connectedDevice?.address) {
        _isConnected = false;
        _connectedDevice = null;
        onDeviceDisconnected?.call(device);
      }
      return isStale;
    });
  }

  // =====================================================
  // أدوات مساعدة / Utilities
  // =====================================================

  String _getDeviceName() {
    return 'NexusClip Android';
  }

  /// الحصول على عنوان IP المحلي
  /// Get local IP address
  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting local IP: $e');
      }
    }
    return null;
  }
}

/// نموذج جهاز المزامنة
/// Sync device model
class SyncDevice {
  final String address;
  final String platform;
  final String name;
  final DateTime lastSeen;

  const SyncDevice({
    required this.address,
    required this.platform,
    required this.name,
    required this.lastSeen,
  });

  SyncDevice copyWith({
    String? address,
    String? platform,
    String? name,
    DateTime? lastSeen,
  }) {
    return SyncDevice(
      address: address ?? this.address,
      platform: platform ?? this.platform,
      name: name ?? this.name,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  String toString() {
    return 'SyncDevice(name: $name, platform: $platform, address: $address)';
  }
}
