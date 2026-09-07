import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/village_navigation_scope.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const line = Color(0xFFE3D8C9);

  final service = NotificationService();
  List<VillageNotification> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final saved = await service.load();
    if (!mounted) return;
    setState(() {
      notifications = saved;
      loading = false;
    });
  }

  Future<void> openNotification(VillageNotification item) async {
    notifications = await service.markRead(notifications, item.id);
    if (!mounted) return;
    setState(() {});
    VillageNavigationScope.of(context).onSelect(item.destinationIndex);
  }

  Future<void> markAllRead() async {
    notifications = await service.markAllRead(notifications);
    if (mounted) setState(() {});
  }

  String timeLabel(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        title: Text(
          'Notifications',
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: notifications.any((item) => !item.isRead)
                ? markAllRead
                : null,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text('You have no notifications yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (_, index) {
                    final item = notifications[index];
                    return Material(
                      color: item.isRead
                          ? Colors.white.withValues(alpha: .55)
                          : paleSage,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: line),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        onTap: () => openNotification(item),
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          backgroundColor:
                              item.isRead ? Colors.white : const Color(0xFFFFE8BE),
                          child: Icon(
                            item.destinationIndex == 1
                                ? Icons.groups_2_outlined
                                : item.destinationIndex == 3
                                    ? Icons.chat_bubble_outline_rounded
                                    : Icons.favorite_outline_rounded,
                            color: item.isRead ? sage : gold,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight:
                                item.isRead ? FontWeight.w600 : FontWeight.w800,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text('${item.message}\n${timeLabel(item.createdAt)}'),
                        ),
                        trailing: item.isRead
                            ? null
                            : const Icon(Icons.circle, color: sage, size: 10),
                      ),
                    );
                  },
                ),
    );
  }
}
