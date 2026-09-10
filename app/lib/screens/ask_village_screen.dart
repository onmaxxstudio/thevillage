import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../navigation/village_navigation_scope.dart';
import '../services/profile_service.dart';
import 'post_preview_screen.dart';

class AskVillageScreen extends StatefulWidget {
  const AskVillageScreen({
    super.key,
    this.initialQuestion,
    this.initialCategory,
    this.initialSupportIntent,
    this.initialCommunityId,
    this.initialCommunityName,
    this.suggestionId,
    this.onSuggestedQuestionPosted,
  });

  final String? initialQuestion;
  final String? initialCategory;
  final String? initialSupportIntent;
  final String? initialCommunityId;
  final String? initialCommunityName;
  final String? suggestionId;
  final Future<void> Function(String suggestionId)? onSuggestedQuestionPosted;

  @override
  State<AskVillageScreen> createState() => _AskVillageScreenState();
}

class _AskVillageScreenState extends State<AskVillageScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF496B4F);
  static const gold = Color(0xFFC8A35E);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final questionController = TextEditingController();
  final preferences = SharedPreferencesAsync();
  bool anonymous = false;
  bool needsSupport = false;
  String audience = 'The Village';
  String category = 'Relationships';
  String supportIntent = 'Advice';
  String currentUsername = 'VillageMember';

  static const _draftKey = 'ask_the_village_current_draft';
  String get draftKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'signed_out';
    return '${_draftKey}_$uid';
  }

  static const supportIntents = [
    ('Advice', Icons.lightbulb_outline_rounded),
    ('Just listen', Icons.hearing_rounded),
    ('Encouragement', Icons.favorite_border_rounded),
    ('Prayer', Icons.auto_awesome_outlined),
    ('Practical help', Icons.handshake_outlined),
  ];

  static const categories = [
    'Relationships',
    'Mental Health',
    'Parenting',
    'Life & Growth',
    'Friendship',
    'Work & School',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    questionController.text = widget.initialQuestion ?? '';
    if (categories.contains(widget.initialCategory)) {
      category = widget.initialCategory!;
    }
    if (supportIntents.any((item) => item.$1 == widget.initialSupportIntent)) {
      supportIntent = widget.initialSupportIntent!;
    }
    currentUsername =
        ProfileService.usernameNotifier.value ?? 'VillageMember';
    ProfileService.usernameNotifier.addListener(_usernameChanged);
    ProfileService.currentUsername();
  }

  void _usernameChanged() {
    final value = ProfileService.usernameNotifier.value?.trim();
    if (mounted && value != null && value.isNotEmpty) {
      setState(() => currentUsername = value);
    }
  }

  @override
  void dispose() {
    ProfileService.usernameNotifier.removeListener(_usernameChanged);
    questionController.dispose();
    super.dispose();
  }

  Future<void> preview() async {
    final question = questionController.text.trim();
    if (question.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a little more before previewing.')),
      );
      return;
    }
    final crisisLanguage = RegExp(
      r'\b(suicide|kill myself|end my life|hurt myself|self harm|want to die)\b',
      caseSensitive: false,
    ).hasMatch(question);
    if (crisisLanguage) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: cream,
          title: const Text('You deserve immediate support'),
          content: const Text(
            'The Village is peer support and cannot provide emergency help. In the U.S., call or text 988 for crisis support. If anyone is in immediate danger, call 911.',
          ),
          actions: [
            TextButton(
              onPressed: () => launchUrl(Uri(scheme: 'sms', path: '988')),
              child: const Text('Text 988'),
            ),
            FilledButton(
              onPressed: () => launchUrl(Uri(scheme: 'tel', path: '988')),
              child: const Text('Call 988'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Continue to Preview'),
            ),
          ],
        ),
      );
      if (!mounted) return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostPreviewScreen(
          post: VillagePostDraft(
            question: question,
            category: category,
            audience: audience,
            anonymous: anonymous,
            needsSupport: needsSupport,
            supportIntent: supportIntent,
            username: currentUsername,
            communityId: widget.initialCommunityId,
            communityName: widget.initialCommunityName,
          ),
          suggestionId: widget.suggestionId,
          suggestedQuestionText:
              widget.suggestionId == null ? null : widget.initialQuestion,
          onSuggestedQuestionPosted: widget.onSuggestedQuestionPosted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        leading: IconButton(
          onPressed: () =>
              VillageNavigationScope.of(context).onSelect(0),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Column(
          children: [
            Image.asset('assets/images/welcome_branch.png', height: 20),
            Text(
              'Ask the Village',
              style: GoogleFonts.playfairDisplay(
                color: sage,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _restoreDraft,
            icon: const Icon(Icons.note_alt_outlined),
            label: const Text('Drafts'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                _section(
                  title: 'How would you like to ask?',
                  subtitle: 'You’re in control. Choose how you show up.',
                  child: Row(
                    children: [
                      Expanded(
                        child: _choiceCard(
                          selected: !anonymous,
                          icon: Icons.person_rounded,
                          title: 'Use my username',
                          subtitle: '@$currentUsername',
                          onTap: () => setState(() => anonymous = false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _choiceCard(
                          selected: anonymous,
                          icon: Icons.visibility_off_outlined,
                          title: 'Anonymous Neighbor',
                          subtitle: 'Share anonymously',
                          onTap: () => setState(() => anonymous = true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  title: 'What kind of support do you want?',
                  subtitle: 'This helps people respond in the way you need.',
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final intent in supportIntents)
                        ChoiceChip(
                          avatar: Icon(intent.$2, size: 17),
                          label: Text(intent.$1),
                          selected: supportIntent == intent.$1,
                          selectedColor: const Color(0xFFE8EBDD),
                          side: BorderSide(
                            color: supportIntent == intent.$1 ? sage : line,
                          ),
                          onSelected: (_) =>
                              setState(() => supportIntent = intent.$1),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  title: 'Who can see your post?',
                  subtitle: 'Public questions belong in the Village. Private reach-outs belong in your trusted Circle.',
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3E9),
                          border: Border.all(color: sage),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.groups_outlined, color: sage),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'The Village — visible to signed-in community members',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.check_circle, color: sage),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () =>
                            VillageNavigationScope.of(context).onSelect(1),
                        icon: const Icon(Icons.lock_outline_rounded),
                        label: const Text('Send a private reach-out to My Circle'),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1DE),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Need Support Today?', style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: const Text('Let neighbors know you could use extra support.'),
                          secondary: const Icon(Icons.volunteer_activism_outlined, color: gold, size: 34),
                          activeThumbColor: sage,
                          value: needsSupport,
                          onChanged: (value) => setState(() => needsSupport = value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  title: 'What’s your post about?',
                  subtitle: 'Choose the category that fits best.',
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final item in categories)
                        ChoiceChip(
                          label: Text(item),
                          selected: category == item,
                          selectedColor: const Color(0xFFE8EBDD),
                          side: BorderSide(color: category == item ? sage : line),
                          onSelected: (_) => setState(() => category = item),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  title: 'What’s on your mind?',
                  subtitle: 'There’s no perfect way to ask. Just start where you are.',
                  child: Column(
                    children: [
                      TextField(
                        controller: questionController,
                        maxLength: 1500,
                        minLines: 6,
                        maxLines: 10,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Write your question or share what’s going on…',
                          filled: true,
                          fillColor: cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: sage, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _helper(
                            Icons.auto_awesome_outlined,
                            'Help me find\nthe words',
                            () => _writingHelp('starter'),
                          ),
                          _helper(
                            Icons.lightbulb_outline_rounded,
                            'Tips for a\ngreat post',
                            () => _writingHelp('tips'),
                          ),
                          _helper(
                            Icons.content_copy_outlined,
                            'Example\nquestion',
                            () => _writingHelp('example'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F1E8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: sage),
                      SizedBox(width: 10),
                      Expanded(child: Text('Your privacy matters. Never share private identifying information.')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveDraft,
                        icon: const Icon(Icons.bookmark_border_rounded),
                        label: const Text('Save Draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: preview,
                        style: FilledButton.styleFrom(backgroundColor: sage, padding: const EdgeInsets.all(16)),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Preview Post'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .38),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _choiceCard({required bool selected, required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F3E9) : cream,
          border: Border.all(color: selected ? sage : line, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(backgroundColor: const Color(0xFFE5E7D9), child: Icon(icon, color: sage)),
                  const SizedBox(height: 9),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (selected) const Positioned(right: 0, top: 0, child: Icon(Icons.check_circle, color: sage)),
          ],
        ),
      ),
    );
  }

  Widget _helper(IconData icon, String text, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(children: [Icon(icon, color: gold, size: 21), Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))]),
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    await preferences.setString(
      draftKey,
      jsonEncode({
        'question': questionController.text,
        'category': category,
        'audience': audience,
        'anonymous': anonymous,
        'needsSupport': needsSupport,
        'supportIntent': supportIntent,
      }),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved on this device.')),
    );
  }

  Future<void> _restoreDraft() async {
    final raw = await preferences.getString(draftKey);
    if (!mounted) return;
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have a saved draft yet.')),
      );
      return;
    }
    try {
      final draft = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        questionController.text = draft['question'] as String? ?? '';
        category = draft['category'] as String? ?? category;
        audience = 'The Village';
        anonymous = draft['anonymous'] as bool? ?? anonymous;
        needsSupport = draft['needsSupport'] as bool? ?? needsSupport;
        supportIntent = draft['supportIntent'] as String? ?? supportIntent;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your draft was restored.')),
      );
    } on Object {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That draft could not be opened.')),
      );
    }
  }

  Future<void> _writingHelp(String type) async {
    final message = switch (type) {
      'starter' =>
        'Try: “I’m going through ____. What I need most right now is ____.”',
      'tips' =>
        'Share only what feels safe. Say what happened, how you feel, and what kind of response would help.',
      _ =>
        '“I’m feeling overwhelmed by a change at home. I don’t need solutions yet—could someone just listen?”',
    };
    final useText = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cream,
        title: const Text('A gentle way to begin'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Close'),
          ),
          if (type != 'tips')
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Use This'),
            ),
        ],
      ),
    );
    if (useText == true && mounted) {
      setState(() => questionController.text = message.replaceAll('Try: ', ''));
    }
  }
}
