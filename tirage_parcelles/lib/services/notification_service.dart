// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'faso_nere_channel';
  static const _channelName = 'Faso Nere';

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> notificationsVersion = ValueNotifier<int>(0);
  final List<AppNotification> _notifications = [];
  Timer? _pollingTimer;
  String? _lastSeenId;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// Démarre le polling automatique (toutes les 30s)
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollForNew());
  }

  /// Arrête le polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Poll pour de nouvelles notifications et envoie une notification locale si nécessaire
  Future<void> _pollForNew() async {
    try {
      final res = await api.get('/notifications?unread=true');
      final items = (res['notifications'] as List<dynamic>?) ?? [];
      if (items.isEmpty) return;

      // Vérifier si on a de nouvelles notifs depuis la dernière fois
      final newest = items.first as Map<String, dynamic>;
      final newestId = newest['id'].toString();

      if (_lastSeenId != null && newestId != _lastSeenId) {
        // Il y a de nouvelles notifs — afficher une push locale
        final titre = newest['titre'] as String? ?? 'Nouvelle notification';
        final message = newest['message'] as String? ?? '';
        await showSysteme(titre, message);
      }
      _lastSeenId = newestId;

      // Recharger la liste complète
      _notifications.clear();
      for (final data in items) {
        _notifications.add(AppNotification.fromJson(data as Map<String, dynamic>));
      }
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _updateListeners();
    } catch (_) {}
  }

  void _updateListeners() {
    unreadCountNotifier.value = unreadCount;
    notificationsVersion.value += 1;
  }

  /// Charge les notifications depuis le backend
  Future<void> fetchNotifications({bool unread = false}) async {
    try {
      final query = unread ? '?unread=true' : '';
      final res = await api.get('/notifications$query');
      final items = (res['notifications'] as List<dynamic>?) ?? [];
      _notifications.clear();
      for (final data in items) {
        final notif = AppNotification.fromJson(data as Map<String, dynamic>);
        _notifications.add(notif);
      }
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _updateListeners();
    } catch (_) {
      // Ignorer si aucune connexion ou erreur réseau
    }
  }

  /// Recharge toutes les notifications
  Future<void> reloadNotifications() async {
    _notifications.clear();
    await fetchNotifications();
  }

  /// Initialise le service
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,   // On gère manuellement
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // Création du canal Android
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications Faso Nere',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Demande les permissions de notification (Android + iOS)
  Future<bool> requestPermissions() async {
    bool granted = false;

    // === Android ===
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      granted = status.isGranted;
    } else {
      granted = true;
    }

    // === iOS ===
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }

    return granted;
  }

  /// Méthode générique pour afficher une notification
  Future<void> show({
    int? id,
    required String titre,
    required String message,
    String type = 'systeme',
  }) async {
    final notifId = id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _plugin.show(
      id: notifId,
      title: titre,
      body: message,
      payload: type,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notifications Faso Nere',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          number: unreadCount + 1,
          styleInformation: BigTextStyleInformation(message),
        ),
      ),
    );

    _notifications.insert(0, AppNotification(
      id: notifId.toString(),
      titre: titre,
      message: message,
      type: type,
      timestamp: DateTime.now(),
    ));
    _updateListeners();
  }

  // ==================== Méthodes de commodité ====================

  Future<void> showOtp(String code) async {
    await show(
      id: 0,
      titre: '🔐 Code de vérification',
      message: 'Votre code de vérification : $code. Valable 5 minutes.',
      type: 'otp',
    );
  }

  Future<void> showGain(String cadeauNom, String valeur) async {
    await show(
      titre: '🎉 Félicitations !',
      message: 'Vous avez gagné : $cadeauNom ($valeur FCFA)',
      type: 'gain',
    );
  }

  Future<void> showPaiement(String message) async {
    await show(
      titre: '💰 Paiement',
      message: message,
      type: 'paiement',
    );
  }

  Future<void> showSysteme(String titre, String message) async {
    await show(titre: titre, message: message, type: 'systeme');
  }

  void markAllRead() {
    for (final notif in _notifications) {
      notif.isRead = true;
    }
    _updateListeners();
  }

  void markRead(int index) {
    if (index < 0 || index >= _notifications.length) return;
    _notifications[index].isRead = true;
    _updateListeners();
  }

  void resetUnreadCount() {
    for (final notif in _notifications) {
      notif.isRead = true;
    }
    _updateListeners();
    _plugin.cancelAll();
  }

  void _onTap(NotificationResponse response) {
    // Déclencher des actions spécifiques en cas de tap sur la notification.
  }
}

final notificationService = NotificationService.instance;

class AppNotification {
  AppNotification({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    DateTime timestamp;
    if (created is String) {
      timestamp = DateTime.tryParse(created) ?? DateTime.now();
    } else if (created is DateTime) {
      timestamp = created;
    } else {
      timestamp = DateTime.now();
    }

    return AppNotification(
      id: json['id'].toString(),
      titre: json['titre'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'systeme',
      timestamp: timestamp,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  final String id;
  final String titre;
  final String message;
  final String type;
  final DateTime timestamp;
  bool isRead;
}