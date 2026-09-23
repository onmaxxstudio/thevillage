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
    this.firstQuestionFlow = false,
    this.suggestionId,
    this.onSuggestedQuestionPosted,
  });

  final String? initialQuestion;
  final String? initialCategory;
  final String? initialSupportIntent;
  final String? initialCommunityId;
  final String? initialCommunityName;
  final bool firstQuestionFlow;
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
  String category = 'Relationships & Dating';
  String supportIntent = 'Advice';
  String currentUsername = 'VillageMember';

  static const _draftKey = 'ask_the_village_current_draft';
  String get draftKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'signed_out';
    return '${_draftKey}_$uid';
  }

  static const supportIntents = [
    ('Advice', Icons.lightbulb_outline_rounded),
    ('A listening ear', Icons.hearing_rounded),
    ('Encouragement', Icons.favorite_border_rounded),
    ('Resources or practical help', Icons.handshake_outlined),
  ];

  static const categories = [
    'Men',
    'Women',
    'Relationships & Dating',
    'Family & Parenting',
    'Mental Wellness',
    'Friendship',
    'Work & Money',
    'Life Changes & Growth',
    'Health & Self-Care',
    'Faith',
    'Other',
  ];

  static String? _normalizedCategory(String? value) => switch (value) {
        'Relationship & dating' ||
        'Relationships' ||
        'Relationships & Dating' =>
          'Relationships & Dating',
        'Men' => 'Men',
        'Women' => 'Women',
        'Family & parenting' || 'Parenting' || 'Family & Parenting' =>
          'Family & Parenting',
        'Mental wellbeing' || 'Mental Health' || 'Mental Wellness' =>
          'Mental Wellness',
        'Friendship & social life' || 'Friendship' => 'Friendship',
        'Work & money' || 'Work & School' || 'Work & Money' => 'Work & Money',
        'Life changes' || 'Life & Growth' || 'Life Changes & Growth' =>
          'Life Changes & Growth',
        'Health & self-care' || 'Health & Self-Care' =>
          'Health & Self-Care',
        'Faith' => 'Faith',
        'Something else' || 'Other' => 'Other',
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    questionController.text = widget.initialQuestion ?? '';
    category = _normalizedCategory(widget.initialCategory) ?? category;
    if (widget.firstQuestionFlow) {
      anonymous = true;
      category = switch (widget.initialCommunityId) {
        'relationships' => 'Relationships & Dating',
        'men' => 'Men',
        'women' => 'Women',
        'moms' || 'caregivers' => 'Family & Parenting',
        'wellness' || 'grief' => 'Mental Wellness',
        'career' => 'Work & Money',
        'friendship' => 'Friendship',
        'new_beginnings' => 'Life Changes & Growth',
        'faith' => 'Faith',
        _ => 'Other',
      };
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
            audience: 'The Village',
            anonymous: anonymous,
            needsSupport: needsSupport,
            supportIntent: supportIntent,
            username: currentUsername,
            welcomesPrayer: false,
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
    if (widget.firstQuestionFlow) return _firstQuestionScreen();
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        toolbarHeight: 92,
        leadingWidth: 60,
        leading: const SizedBox(width: 60),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/welcome_branch.png', height: 18),
              const SizedBox(height: 3),
              Text(
                'Ask the Village',
                style: GoogleFonts.playfairDisplay(
                  color: sage,
                  fontSize: 42,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Restore draft',
            onPressed: _restoreDraft,
            icon: const Icon(Icons.note_alt_outlined),
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
                if (widget.initialCommunityName?.trim().isNotEmpty ?? false) ...[
                  _communityDestinationBanner(),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    value: anonymous,
                    onChanged: (value) => setState(() => anonymous = value),
                    secondary: const Icon(Icons.visibility_off_outlined, color: sage),
                    title: const Text('Post anonymously', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Your name will not be shown.'),
                  ),
                  const SizedBox(height: 10),
                ],
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
                _section(
                  title: 'What’s this about?',
                  subtitle: 'Choose the topic that fits best.',
                  child: _topicChoices(),
                ),
                const SizedBox(height: 14),
                _section(
                  title: 'What would help most right now?',
                  subtitle: 'Choose the kind of response that would feel helpful.',
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
                if (!(widget.initialCommunityName?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 14),
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
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1DE),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Need Support Today?',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Let neighbors know you could use extra support.',
                    ),
                    secondary: const Icon(
                      Icons.volunteer_activism_outlined,
                      color: gold,
                      size: 34,
                    ),
                    activeThumbColor: sage,
                    value: needsSupport,
                    onChanged: (value) =>
                        setState(() => needsSupport = value),
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

  Widget _firstQuestionScreen() => Scaffold(
    backgroundColor: cream,
    appBar: AppBar(
      backgroundColor: cream,
      leading: IconButton(
        onPressed: () => VillageNavigationScope.of(context).onSelect(4),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text('Ask your community', style: GoogleFonts.playfairDisplay(color: sage, fontWeight: FontWeight.w700)),
      centerTitle: true,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              _communityDestinationBanner(),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                value: anonymous,
                onChanged: (value) => setState(() => anonymous = value),
                secondary: const Icon(Icons.visibility_off_outlined, color: sage),
                title: const Text('Post anonymously', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Your name will not be shown.'),
              ),
              const SizedBox(height: 8),
              _section(
                title: 'What’s been on your mind lately?',
                subtitle: 'You do not need the perfect words. Start where you are.',
                child: TextField(
                  controller: questionController,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 1500,
                  decoration: InputDecoration(
                    hintText: 'Share your question or what is going on…',
                    filled: true,
                    fillColor: cream,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _section(
                title: 'What would help most?',
                subtitle: 'This lets people know how to show up for you.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in supportIntents)
                      ChoiceChip(
                        avatar: Icon(option.$2, size: 17),
                        label: Text(option.$1),
                        selected: supportIntent == option.$1,
                        selectedColor: const Color(0xFFE8EBDD),
                        side: BorderSide(color: supportIntent == option.$1 ? sage : line),
                        onSelected: (_) => setState(() => supportIntent = option.$1),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: needsSupport,
                onChanged: (value) => setState(() => needsSupport = value),
                secondary: const Icon(Icons.volunteer_activism_outlined, color: gold),
                title: const Text('I need extra support today', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Let neighbors know this feels especially important.'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: preview,
                style: FilledButton.styleFrom(backgroundColor: sage, padding: const EdgeInsets.all(16)),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Preview my question'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _communityDestinationBanner() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3E9),
        border: Border.all(color: sage),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: sage,
            child: Icon(Icons.forum_outlined, color: Colors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posting in ' + widget.initialCommunityName!,
                  style: const TextStyle(
                    color: sage,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your post will be clearly marked as a community conversation.',
                  style: TextStyle(fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
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

  Widget _topicChoices() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 7.0;
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        final cellWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        final remainder = categories.length % columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < categories.length; index++)
              SizedBox(
                width: index == categories.length - 1 && remainder != 0
                    ? (cellWidth * (columns - remainder + 1)) +
                        (gap * (columns - remainder))
                    : cellWidth,
                height: 46,
                child: ChoiceChip(
                  label: SizedBox(
                    width: double.infinity,
                    child: Text(
                      categories[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  selected: category == categories[index],
                  selectedColor: const Color(0xFFE8EBDD),
                  side: BorderSide(
                    color: category == categories[index] ? sage : line,
                  ),
                  onSelected: (_) =>
                      setState(() => category = categories[index]),
                ),
              ),
          ],
        );
      },
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
