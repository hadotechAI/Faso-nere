import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/ui_components.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    notificationService.notificationsVersion.addListener(_refresh);
    notificationService.fetchNotifications();
  }

  @override
  void dispose() {
    notificationService.notificationsVersion.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final notifications = notificationService.notifications;
    return AppScaffold(
      title: 'Notifications',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (notifications.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Text('Aucune notification pour le moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey, fontSize: 14)),
            ),
          ] else ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Mes notifications',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white)),
              TextButton(
                onPressed: notificationService.notifications.isEmpty
                    ? null
                    : () {
                        notificationService.markAllRead();
                        setState(() {});
                      },
                child: Text('Tout marquer lu', style: TextStyle(color: AppColors.gold)),
              ),
            ]),
            const SizedBox(height: 16),
            ...List.generate(notifications.length, (index) {
              final notif = notifications[index];
              
              // Détermination de l'icône et couleur selon le titre
              IconData iconData = Icons.notifications_none;
              Color iconBgColor = AppColors.goldDark;
              final t = notif.titre.toLowerCase();
              if (t.contains('dommage') || t.contains('perdu')) {
                iconData = Icons.sentiment_dissatisfied;
                iconBgColor = const Color(0xFFB87A10);
              } else if (t.contains('retrait')) {
                iconData = Icons.money;
                iconBgColor = const Color(0xFF2E7D32);
              } else if (t.contains('otp') || t.contains('code')) {
                iconData = Icons.lock_outline;
                iconBgColor = const Color(0xFF5E35B1);
              } else if (t.contains('dépôt') || t.contains('depot')) {
                iconData = Icons.account_balance_wallet;
                iconBgColor = const Color(0xFF1976D2);
              } else if (t.contains('cadeau') || t.contains('gain')) {
                iconData = Icons.card_giftcard;
                iconBgColor = const Color(0xFFE65100);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DarkCard(
                  color: notif.isRead ? AppColors.surface : AppColors.surface2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      notificationService.markRead(index);
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notif.titre,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white)),
                                const SizedBox(height: 8),
                                Text(notif.message,
                                    style: TextStyle(
                                        fontSize: 14, color: AppColors.greyLight, height: 1.4)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: AppColors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${notif.timestamp.hour.toString().padLeft(2, '0')}:${notif.timestamp.minute.toString().padLeft(2, '0')} • ${notif.timestamp.day.toString().padLeft(2, '0')}/${notif.timestamp.month.toString().padLeft(2, '0')}/${notif.timestamp.year}',
                                      style: TextStyle(
                                          fontSize: 12, color: AppColors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!notif.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  shape: BoxShape.circle),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ]),
      ),
    );
  }
}
