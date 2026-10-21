import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/private_message_service.dart';
import '../services/profile_service.dart';
import '../widgets/village_avatar.dart';

class PrivateMessagesScreen extends StatefulWidget {
  const PrivateMessagesScreen({
    super.key,
    this.communityId,
    this.communityName,
  });

  final String? communityId;
  final String? communityName;

  @override
  State<PrivateMessagesScreen> createState() => _PrivateMessagesScreenState();
}

class _PrivateMessagesScreenState extends State<PrivateMessagesScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final service = PrivateMessageService();
  final Map<String, Future<String?>> _usernames = {};
  String? scope;

  @override
  void initState() {
    super.initState();
    scope = widget.communityId;
  }

  String _time(DateTime value) {
    final now = DateTime.now();
    if (now.difference(value).inDays == 0) {
      final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
      return '$hour:${value.minute.toString().padLeft(2, '0')} ${value.hour < 12 ? 'AM' : 'PM'}';
    }
    if (now.difference(value).inDays == 1) return 'Yesterday';
    return '${value.month}/${value.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        title: Text('Messages', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<PrivateConversation>>(
        stream: service.watchConversations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Messages are unavailable right now.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: sage));
          }
          final conversations = [...snapshot.data!]
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final communityNames = <String, String>{};
          for (final conversation in conversations) {
            if (conversation.sourceType == 'community' && conversation.communityId.isNotEmpty) {
              communityNames[conversation.communityId] = conversation.communityName;
            }
          }
          final visible = conversations.where((conversation) {
            if (scope == null) return true;
            if (scope == 'village') return conversation.sourceType == 'village';
            return conversation.sourceType == 'community' && conversation.communityId == scope;
          }).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  widget.communityName == null
                      ? 'All your private conversations in one place'
                      : 'Private chats from ${widget.communityName}',
                  style: GoogleFonts.inter(color: const Color(0xFF667066)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFE9EEE4), borderRadius: BorderRadius.circular(14)),
                  child: const Row(children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: sage),
                    SizedBox(width: 8),
                    Expanded(child: Text('Only you and the other member can see these chats.', style: TextStyle(fontSize: 12, color: ink))),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _scopeChip('All messages', null),
                  _scopeChip('Village feed', 'village'),
                  for (final entry in communityNames.entries)
                    _scopeChip(entry.value.isEmpty ? 'Community' : entry.value, entry.key),
                ]),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.chat_bubble_outline_rounded, color: sage, size: 38),
                            const SizedBox(height: 12),
                            Text('Your private chats will appear here', textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 20, color: sage, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            const Text('Start a conversation from a member’s reply in the Village feed or a community.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF667066))),
                          ]),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: line),
                        itemBuilder: (context, index) => _conversationTile(visible[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _scopeChip(String label, String? value) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ChoiceChip(
          label: Text(label, overflow: TextOverflow.ellipsis),
          selected: scope == value,
          onSelected: (_) => setState(() => scope = value),
          selectedColor: sage,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(color: scope == value ? Colors.white : ink, fontSize: 11, fontWeight: FontWeight.w700),
          side: BorderSide(color: scope == value ? sage : line),
        ),
      );

  Widget _conversationTile(PrivateConversation conversation) {
    final otherUid = conversation.otherUid;
    final source = conversation.sourceType == 'community'
        ? (conversation.communityName.isEmpty ? 'Community' : conversation.communityName)
        : 'Village feed';
    return FutureBuilder<String?>(
      future: _usernames.putIfAbsent(
        otherUid,
        () => ProfileService.publicUsername(otherUid),
      ),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Village member';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          leading: VillageAvatar(uid: otherUid, radius: 25),
          title: Row(children: [
            Expanded(child: Text('@$name', style: const TextStyle(fontWeight: FontWeight.w800, color: ink))),
            Text(_time(conversation.updatedAt), style: const TextStyle(fontSize: 11, color: Color(0xFF777D75))),
          ]),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 3),
            Text(conversation.lastMessage.isEmpty ? conversation.data['contextExcerpt'] as String? ?? 'Private conversation started' : conversation.lastMessage, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              _badge(Icons.lock_outline_rounded, 'Private', const Color(0xFFE9EEE4)),
              _badge(Icons.forum_outlined, source, const Color(0xFFF5EBDD)),
              if (conversation.unreadForMe)
                const Icon(Icons.circle, size: 9, color: Color(0xFFB78943)),
            ]),
          ]),
          trailing: const Icon(Icons.chevron_right_rounded, color: sage),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => PrivateChatScreen(
              conversationId: conversation.id,
              otherUid: otherUid,
              contextExcerpt: conversation.data['contextExcerpt'] as String? ?? '',
              sourceLabel: source,
            ),
          )),
        );
      },
    );
  }

  Widget _badge(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: sage), const SizedBox(width: 3), Text(label, style: const TextStyle(fontSize: 9.5, color: ink, fontWeight: FontWeight.w700))]),
      );
}

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUid,
    this.contextExcerpt = '',
    this.sourceLabel = 'Village feed',
  });

  final String conversationId;
  final String otherUid;
  final String contextExcerpt;
  final String sourceLabel;

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  final service = PrivateMessageService();
  final controller = TextEditingController();
  final scrollController = ScrollController();
  bool sending = false;

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (sending || controller.text.trim().isEmpty) return;
    final text = controller.text.trim();
    setState(() => sending = true);
    try {
      await service.send(widget.conversationId, text);
      controller.clear();
    } on Object {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your message could not be sent. Please try again.')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          backgroundColor: cream,
          foregroundColor: ink,
          elevation: 0,
          title: FutureBuilder<String?>(
            future: ProfileService.publicUsername(widget.otherUid),
            builder: (context, snapshot) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(snapshot.data == null ? 'Private chat' : '@${snapshot.data}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
              const Text('Private conversation', style: TextStyle(fontSize: 10, color: Color(0xFF667066))),
            ]),
          ),
          actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.lock_outline_rounded, color: sage, size: 20))],
        ),
        body: Column(children: [
          if (widget.contextExcerpt.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE9EEE4), borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('From ${widget.sourceLabel}', style: const TextStyle(fontSize: 10, color: sage, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(widget.contextExcerpt, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: ink)),
              ]),
            ),
          Expanded(
            child: StreamBuilder<List<PrivateChatMessage>>(
              stream: service.watchMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('This private chat is unavailable.'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: sage));
                final messages = snapshot.data!;
                if (messages.isNotEmpty) {
                  service.markRead(widget.conversationId);
                }
                if (messages.isEmpty) return const Center(child: Text('Say hello to start the conversation.'));
                return ListView.builder(
                  reverse: true,
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - index - 1];
                    final mine = message.senderUid == FirebaseAuth.instance.currentUser?.uid;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 310),
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: mine ? sage : Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: Text(message.text, style: TextStyle(color: mine ? Colors.white : ink)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(children: [
                Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 4, maxLength: 2000, decoration: InputDecoration(counterText: '', hintText: 'Write a private message…', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: sending ? null : _send, style: IconButton.styleFrom(backgroundColor: sage), icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded)),
              ]),
            ),
          ),
        ]),
      );
}
