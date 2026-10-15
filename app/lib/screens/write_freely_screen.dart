import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/private_journal_service.dart';

const _cream = Color(0xFFFFFAF1);
const _paper = Color(0xFFFFFDF8);
const _green = Color(0xFF355C3B);
const _ink = Color(0xFF28332B);
const _sage = Color(0xFFE7EBDD);
const _line = Color(0xFFE7DED1);
const _journalTags = [
  'Relationships',
  'Work',
  'Family',
  'Personal Growth',
  'Health',
  'Other',
];

String _dateLabel(DateTime? value, {bool includeTime = false}) {
  final date = value ?? DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day = date.day.toString();
  final base = '${months[date.month - 1]} $day, ${date.year}';
  if (!includeTime) return base;
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$base · $hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
}

class WriteFreelyEditorScreen extends StatefulWidget {
  const WriteFreelyEditorScreen({
    required this.journal,
    this.draft,
    this.entry,
    super.key,
  });

  final PrivateJournalService journal;
  final PrivateJournalDraft? draft;
  final PrivateJournalEntry? entry;

  @override
  State<WriteFreelyEditorScreen> createState() => _WriteFreelyEditorScreenState();
}

class _WriteFreelyEditorScreenState extends State<WriteFreelyEditorScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _title;
  late final TextEditingController _body;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _bodyFocus = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final SpeechToText _speech = SpeechToText();
  final List<String> _tags = [];
  final List<String> _attachments = [];
  final List<String> _removedAttachments = [];
  Timer? _draftTimer;
  String? _entryId;
  String _saveState = 'Your draft saves as you write.';
  String? _saveError;
  String _speechBase = '';
  bool _savingDraft = false;
  bool _savingEntry = false;
  bool _uploading = false;
  bool _speechReady = false;
  bool _restoringDraft = false;

  bool get _hasExisting => widget.entry != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final entry = widget.entry;
    final draft = widget.draft;
    _title = TextEditingController(text: entry?.title ?? draft?.title ?? '');
    _body = TextEditingController(text: entry?.body ?? draft?.body ?? '');
    _tags.addAll(entry?.tags ?? draft?.tags ?? const []);
    _attachments.addAll(entry?.attachments ?? draft?.attachments ?? const []);
    _entryId = entry?.id ?? draft?.entryId;
    _titleFocus.addListener(_onInputFocusChanged);
    _bodyFocus.addListener(_onInputFocusChanged);
    _title.addListener(_scheduleDraftSave);
    _body.addListener(_scheduleDraftSave);
    if (entry == null && draft == null) {
      _restoringDraft = true;
      _saveState = 'Checking for a saved draft…';
      unawaited(_restoreDraft());
    }
    if (draft?.hasContent == true && entry == null) {
      _saveState = 'Draft restored';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    if (!_savingEntry && _hasAnyContent) unawaited(_persistDraft());
    _title.dispose();
    _body.dispose();
    _editorScrollController.dispose();
    _titleFocus.removeListener(_onInputFocusChanged);
    _bodyFocus.removeListener(_onInputFocusChanged);
    _titleFocus.dispose();
    _bodyFocus.dispose();
    unawaited(_speech.stop());
    super.dispose();
  }

  bool get _hasAnyContent =>
      _title.text.trim().isNotEmpty || _body.text.trim().isNotEmpty || _tags.isNotEmpty || _attachments.isNotEmpty;

  bool get _hasInputFocus => _titleFocus.hasFocus || _bodyFocus.hasFocus;

  void _onInputFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _draftTimer?.cancel();
      if (_hasAnyContent) unawaited(_persistDraft());
    }
  }

  void _scheduleDraftSave() {
    if (_savingEntry || _restoringDraft) return;
    _draftTimer?.cancel();
    setState(() {
      _saveError = null;
      _saveState = 'Unsaved changes';
    });
    _draftTimer = Timer(const Duration(milliseconds: 800), _persistDraft);
  }

  Future<void> _restoreDraft() async {
    try {
      final draft = await widget.journal
          .loadDraft()
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      if (draft?.hasContent == true) {
        _title.value = TextEditingValue(
          text: draft!.title,
          selection: TextSelection.collapsed(offset: draft.title.length),
        );
        _body.value = TextEditingValue(
          text: draft.body,
          selection: TextSelection.collapsed(offset: draft.body.length),
        );
        _tags
          ..clear()
          ..addAll(draft.tags);
        _attachments
          ..clear()
          ..addAll(draft.attachments);
        _entryId = draft.entryId;
        _saveState = 'Draft restored';
      } else {
        _saveState = 'Your draft saves as you write.';
      }
    } catch (_) {
      if (mounted) {
        _saveState = 'Could not check for a saved draft';
        _saveError = 'You can keep writing. Reconnect to save your changes.';
      }
    } finally {
      if (mounted) {
        setState(() => _restoringDraft = false);
      }
    }
  }

  Future<void> _persistDraft() async {
    if (_savingEntry) return;
    while (_savingDraft) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      if (_savingEntry) return;
    }
    if (!_hasAnyContent) {
      if (_entryId != null && widget.entry == null) {
        try {
          await widget.journal.clearDraft();
          _entryId = null;
          if (mounted) setState(() => _saveState = 'Your draft saves as you write.');
        } catch (_) {
          if (mounted) setState(() => _saveState = 'Draft not cleared');
        }
      }
      return;
    }
    _savingDraft = true;
    if (mounted) setState(() => _saveState = 'Saving draft…');
    try {
      _entryId = await widget.journal.saveDraft(
        title: _title.text,
        body: _body.text,
        tags: _tags,
        attachments: _attachments,
        entryId: _entryId,
      );
      if (mounted) {
        setState(() {
          _saveState = 'Draft saved';
          _saveError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveState = 'Draft not saved';
          _saveError = 'Reconnect and try again. Your latest changes may not be saved.';
        });
      }
    } finally {
      _savingDraft = false;
    }
  }

  Future<void> _goBack() async {
    _draftTimer?.cancel();
    if (_hasAnyContent) await _persistDraft();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveEntry() async {
    if (_savingEntry || _body.text.trim().isEmpty) return;
    _draftTimer?.cancel();
    setState(() {
      _savingEntry = true;
      _saveError = null;
    });
    try {
      final id = _entryId ?? widget.journal.uid + DateTime.now().microsecondsSinceEpoch.toString();
      final saved = await widget.journal.saveEntry(
        title: _title.text,
        body: _body.text,
        tags: _tags,
        attachments: _attachments,
        entryId: id,
        existing: widget.entry,
      );
      for (final path in _removedAttachments) {
        try { await widget.journal.deleteImage(path); } catch (_) { /* saved entry no longer references this image */ }
      }
      if (!mounted) return;
      var entries = <PrivateJournalEntry>[saved];
      try {
        entries = await widget.journal.loadEntries();
      } catch (_) {
        // The saved document is confirmed; show it even if refreshing the list fails.
      }
      final index = entries.indexWhere((item) => item.id == saved.id);
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => SavedJournalEntryScreen(
          journal: widget.journal,
          entry: index < 0 ? saved : entries[index],
          entries: index < 0 ? [saved, ...entries] : entries,
          index: index < 0 ? 0 : index,
        ),
      ));
    } catch (_) {
      if (mounted) {
        setState(() {
          _savingEntry = false;
          _saveError = 'Entry not saved. Check your connection and try again.';
        });
      }
    }
  }

  void _wrapSelection(String marker) {
    final value = _body.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final selected = value.text.substring(start, end);
    final replacement = '$marker$selected$marker';
    final newText = value.text.replaceRange(start, end, replacement);
    final newOffset = selected.isEmpty ? start + marker.length : start + replacement.length;
    _body.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    _bodyFocus.requestFocus();
  }

  void _insertBullet() {
    final value = _body.value;
    final offset = value.selection.isValid ? value.selection.start : value.text.length;
    final prefix = offset == 0 || value.text.substring(0, offset).endsWith('\n') ? '' : '\n';
    final insertion = '$prefix• ';
    final text = value.text.replaceRange(offset, offset, insertion);
    final cursor = offset + insertion.length;
    _body.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: cursor));
    _bodyFocus.requestFocus();
  }

  Future<void> _insertLink() async {
    final label = TextEditingController();
    final url = TextEditingController(text: 'https://');
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _paper,
        title: const Text('Add a link'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: label, decoration: const InputDecoration(labelText: 'Link text')),
          TextField(controller: url, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Web address')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Add link')),
        ],
      ),
    );
    final parsedUrl = Uri.tryParse(url.text.trim());
    if (result == true && label.text.trim().isNotEmpty && parsedUrl != null && (parsedUrl.scheme == 'https' || parsedUrl.scheme == 'http')) {
      final value = _body.value;
      final start = value.selection.isValid ? value.selection.start : value.text.length;
      final end = value.selection.isValid ? value.selection.end : value.text.length;
      final text = value.text.replaceRange(start, end, '[${label.text.trim()}](${url.text.trim()})');
      _body.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: start + text.length - value.text.length));
      _bodyFocus.requestFocus();
    }
    label.dispose();
    url.dispose();
  }

  Future<void> _addImages() async {
    try {
      final picks = await _picker.pickMultiImage(imageQuality: 82, maxWidth: 1800);
      if (picks.isEmpty || !mounted) return;
      setState(() => _uploading = true);
      for (final pick in picks.take(4 - _attachments.length)) {
        final bytes = await pick.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) throw StateError('Images must be under 5 MB each.');
        final path = await widget.journal.uploadImage(bytes, pick.name);
        _attachments.add(path);
        await _persistDraft();
      }
      if (mounted) setState(() => _saveState = 'Draft saved');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error is StateError ? error.message : 'Could not attach that image. Please try again.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeImage(String path) async {
    setState(() {
      _attachments.remove(path);
      _removedAttachments.add(path);
    });
    _scheduleDraftSave();
  }

  Future<void> _toggleSpeech() async {
    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() => _speechReady = false);
      return;
    }
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (mounted && status != 'listening') setState(() => _speechReady = false);
        },
        onError: (_) {
          if (mounted) setState(() => _speechReady = false);
        },
      );
      if (!available) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice typing is not supported by this browser.')));
        return;
      }
      _speechBase = _body.text.trimRight();
      final joiner = _speechBase.isEmpty || _speechBase.endsWith('\n') ? '' : ' ';
      if (mounted) setState(() => _speechReady = true);
      await _speech.listen(onResult: (result) {
        final dictated = result.recognizedWords.trim();
        final combined = '$_speechBase$joiner$dictated';
        _body.value = TextEditingValue(text: combined, selection: TextSelection.collapsed(offset: combined.length));
      });
    } catch (_) {
      if (mounted) {
        setState(() => _speechReady = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice typing could not start.')));
      }
    }
  }

  Future<void> _openEntries() async {
    await _persistDraft();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => MyEntriesScreen(journal: widget.journal),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 720;
    return Scaffold(
      backgroundColor: _cream,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              primary: false,
              backgroundColor: _cream,
              foregroundColor: _green,
              centerTitle: true,
              leading: IconButton(
                tooltip: 'Back to My Space',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                onPressed: _goBack,
              ),
              title: Text(
                'Write Freely',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _openEntries,
                  child: const Text(
                    'My Entries',
                    style: TextStyle(color: _green, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
            Expanded(child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 760 : 620),
          child: ListView(
            controller: _editorScrollController,
            primary: false,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              _WriteFreelyBanner(),
              const SizedBox(height: 12),
              Row(children: [const Icon(Icons.calendar_today_rounded, size: 17, color: _green), const SizedBox(width: 8), Text(_dateLabel(DateTime.now()), style: const TextStyle(color: _ink, fontWeight: FontWeight.w500))]),
              const SizedBox(height: 10),
              _surface(
                padding: const EdgeInsets.fromLTRB(15, 9, 15, 12),
                child: TextField(
                  controller: _title,
                  focusNode: _titleFocus,
                  enabled: !_restoringDraft,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: 'Give your entry a title (optional)',
                    hintStyle: TextStyle(color: Color(0xFF7B7A71)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: _ink),
                ),
              ),
              const SizedBox(height: 10),
              _surface(
                padding: const EdgeInsets.fromLTRB(15, 12, 12, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 370),
                    child: TextField(
                      controller: _body,
                      focusNode: _bodyFocus,
                      enabled: !_restoringDraft,
                      minLines: 15,
                      maxLines: null,
                      maxLength: 30000,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'What’s on your mind today?',
                        hintStyle: TextStyle(color: Color(0xFF77796F), fontSize: 17),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16, height: 1.65, color: _ink),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(spacing: 2, runSpacing: 2, children: [
                    _tool(Icons.format_bold_rounded, 'Bold', () => _wrapSelection('**')),
                    _tool(Icons.format_italic_rounded, 'Italic', () => _wrapSelection('_')),
                    _tool(Icons.format_list_bulleted_rounded, 'Bullet point', _insertBullet),
                    _tool(Icons.link_rounded, 'Insert link', _insertLink),
                    _tool(Icons.image_outlined, 'Attach image', _uploading ? null : _addImages),
                    _tool(_speech.isListening ? Icons.mic_rounded : Icons.mic_none_rounded, _speech.isListening ? 'Stop voice typing' : 'Voice typing', _toggleSpeech, selected: _speechReady),
                    const SizedBox(width: 4),
                    Text('${_body.text.length}/30,000', style: const TextStyle(color: Color(0xFF89897E), fontSize: 11)),
                  ]),
                ]),
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Attached images', style: TextStyle(color: _green, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: _attachments.map((path) => _AttachmentTile(path: path, journal: widget.journal, onRemove: () => _removeImage(path))).toList()),
                ])),
              ],
              const SizedBox(height: 10),
              _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Add tags (optional)', style: TextStyle(color: _ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                Wrap(spacing: 7, runSpacing: 5, children: _journalTags.map((tag) {
                  final selected = _tags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: _sage,
                    backgroundColor: _cream,
                    side: BorderSide(color: selected ? _green : _line),
                    labelStyle: TextStyle(color: selected ? _green : _ink, fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                    onSelected: (value) {
                      setState(() => value ? _tags.add(tag) : _tags.remove(tag));
                      _scheduleDraftSave();
                    },
                  );
                }).toList()),
              ])),
              const SizedBox(height: 10),
              Row(children: [
                Icon(_saveError == null ? Icons.auto_awesome_rounded : Icons.cloud_off_rounded, color: _saveError == null ? const Color(0xFFB58B3C) : Colors.deepOrange, size: 21),
                const SizedBox(width: 9),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_saveState, style: const TextStyle(color: _green, fontWeight: FontWeight.w600)),
                  if (_saveError != null) Text(_saveError!, style: const TextStyle(color: Colors.deepOrange, fontSize: 11)),
                ])),
                if (_uploading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ]),
              const SizedBox(height: 5),
            ],
          ),
        ),
      )),
            SafeArea(
        top: false,
        child: Container(
          color: _cream,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 728 : 588),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: double.infinity, height: 50, child: FilledButton(
                  onPressed: _savingEntry || _restoringDraft || _body.text.trim().isEmpty ? null : _saveEntry,
                  style: FilledButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, disabledBackgroundColor: _green.withValues(alpha: .45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: _savingEntry ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                )),
                const SizedBox(height: 6),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_rounded, color: _green, size: 13), SizedBox(width: 6), Flexible(child: Text('Your journal is private. You control what you share.', style: TextStyle(color: _ink, fontSize: 11), textAlign: TextAlign.center))]),
              ]),
            ),
          ),
        ),
      )
          ],
        ),
      ),
    );
  }

  Widget _tool(IconData icon, String label, VoidCallback? action, {bool selected = false}) => IconButton(
        tooltip: label,
        onPressed: action,
        color: selected ? _green : _ink,
        icon: Icon(icon, size: 22),
        visualDensity: VisualDensity.compact,
      );
}

class MyEntriesScreen extends StatefulWidget {
  const MyEntriesScreen({required this.journal, super.key});
  final PrivateJournalService journal;

  @override
  State<MyEntriesScreen> createState() => _MyEntriesScreenState();
}

class _MyEntriesScreenState extends State<MyEntriesScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _calendar = false;
  bool _favoritesOnly = false;
  String? _selectedTag;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _newEntry() async {
    final draft = await widget.journal.loadDraft();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => WriteFreelyEditorScreen(journal: widget.journal, draft: draft?.hasContent == true ? draft : null),
    ));
  }

  Future<void> _openEntry(List<PrivateJournalEntry> entries, int index) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SavedJournalEntryScreen(journal: widget.journal, entries: entries, index: index, entry: entries[index]),
    ));
  }

  String _preview(String body) => body.replaceAll(RegExp(r'[*_`\[\]()]'), '').replaceAll('\n', ' ').trim();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 760;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _green,
        centerTitle: true,
        leading: IconButton(tooltip: 'Back to Write Freely', icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19), onPressed: () => Navigator.pop(context)),
        title: Text('My Entries', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, color: _green)),
        actions: [TextButton.icon(onPressed: _newEntry, icon: const Icon(Icons.add_rounded), label: const Text('New Entry'), style: TextButton.styleFrom(foregroundColor: _green)), const SizedBox(width: 7)],
      ),
      body: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 850 : 720),
        child: StreamBuilder<List<PrivateJournalEntry>>(
          stream: widget.journal.watchEntries(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Your entries could not be loaded. Check your connection and try again.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _green));
            final entries = snapshot.data!;
            final allTags = entries.expand((entry) => entry.tags).toSet().toList()..sort();
            final filtered = entries.where((entry) =>
              '${entry.title} ${entry.body} ${entry.tags.join(' ')}'.toLowerCase().contains(_query) &&
              (!_favoritesOnly || entry.favorite) &&
              (_selectedTag == null || entry.tags.contains(_selectedTag))
            ).toList();
            return Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 3, 16, 10), child: Column(children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('List View'), icon: Icon(Icons.view_list_rounded)),
                    ButtonSegment(value: true, label: Text('Calendar View'), icon: Icon(Icons.calendar_month_rounded)),
                  ],
                  selected: {_calendar},
                  onSelectionChanged: (value) => setState(() => _calendar = value.first),
                  style: ButtonStyle(visualDensity: VisualDensity.compact, foregroundColor: WidgetStateProperty.all(_green)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: _green),
                    hintText: 'Search by title or entry text…',
                    filled: true,
                    fillColor: _paper,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: _line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: _line)),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 7, runSpacing: 4, children: [
                  FilterChip(label: const Text('Favorites'), selected: _favoritesOnly, onSelected: (value) => setState(() => _favoritesOnly = value), selectedColor: _sage),
                  if (_selectedTag != null) InputChip(label: Text(_selectedTag!), onDeleted: () => setState(() => _selectedTag = null), backgroundColor: _sage),
                  ...allTags.take(12).map((tag) => FilterChip(label: Text(tag), selected: _selectedTag == tag, onSelected: (value) => setState(() => _selectedTag = value ? tag : null), selectedColor: _sage)),
                ]),
              ])),
              Expanded(child: entries.isEmpty
                  ? _emptyState(context, _newEntry)
                  : _calendar
                      ? _CalendarEntries(entries: filtered, month: _month, selectedDay: _selectedDay, onMonthChanged: (month) => setState(() => _month = month), onDaySelected: (day) => setState(() => _selectedDay = day), onOpen: (entry) => _openEntry(entries, entries.indexOf(entry)))
                      : filtered.isEmpty
                          ? Center(child: Text(_query.isEmpty ? 'No entries yet.' : 'No entries match that search.', style: const TextStyle(color: Color(0xFF686B65))))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 9),
                              itemBuilder: (context, index) {
                                final entry = filtered[index];
                                final originalIndex = entries.indexOf(entry);
                                return _surface(
                                  onTap: () => _openEntry(entries, originalIndex),
                                  padding: const EdgeInsets.all(13),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Container(width: 50, height: 58, decoration: BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.menu_book_rounded, color: _green, size: 25)),
                                    const SizedBox(width: 11),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(entry.title.trim().isEmpty ? 'Untitled entry' : entry.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.playfairDisplay(fontSize: 17, color: _ink, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 3),
                                      Text(_dateLabel(entry.createdAt, includeTime: true), style: const TextStyle(color: Color(0xFF77796F), fontSize: 11)),
                                      const SizedBox(height: 5),
                                      Text(_preview(entry.body), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 13, height: 1.35)),
                                      if (entry.tags.isNotEmpty) ...[
                                        const SizedBox(height: 7),
                                        Wrap(spacing: 5, runSpacing: 4, children: entry.tags.map((tag) => _tag(tag)).toList()),
                                      ],
                                    ])),
                                    PopupMenuButton<String>(
                                      tooltip: 'Entry actions',
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          final draft = PrivateJournalDraft(title: entry.title, body: entry.body, tags: entry.tags, attachments: entry.attachments, entryId: entry.id);
                                          await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WriteFreelyEditorScreen(journal: widget.journal, draft: draft, entry: entry)));
                                        } else {
                                          await _confirmDelete(context, widget.journal, entry);
                                        }
                                      },
                                      itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
                                    ),
                                  ]),
                                );
                              },
                            )),
            ]);
          },
        ),
      )),
    );
  }
}

Widget _emptyState(BuildContext context, VoidCallback onNew) => Center(child: Padding(
  padding: const EdgeInsets.all(32),
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 78, height: 78, decoration: const BoxDecoration(color: _sage, shape: BoxShape.circle), child: const Icon(Icons.menu_book_rounded, color: _green, size: 35)),
    const SizedBox(height: 15),
    Text('Your pages are waiting.', style: GoogleFonts.playfairDisplay(fontSize: 23, color: _green, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    const Text('This is a private place to collect your thoughts, one entry at a time.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF666A62), height: 1.45)),
    const SizedBox(height: 16),
    FilledButton.icon(onPressed: onNew, icon: const Icon(Icons.edit_rounded), label: const Text('Write your first entry'), style: FilledButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white)),
  ]),
));

class _CalendarEntries extends StatelessWidget {
  const _CalendarEntries({required this.entries, required this.month, required this.selectedDay, required this.onMonthChanged, required this.onDaySelected, required this.onOpen});
  final List<PrivateJournalEntry> entries;
  final DateTime month;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<PrivateJournalEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final entryDays = entries.map((entry) => entry.createdAt).whereType<DateTime>().where((date) => date.year == month.year && date.month == month.month).map((date) => date.day).toSet();
    final selectedEntries = selectedDay == null ? const <PrivateJournalEntry>[] : entries.where((entry) => entry.createdAt?.year == selectedDay!.year && entry.createdAt?.month == selectedDay!.month && entry.createdAt?.day == selectedDay!.day).toList();
    final cellCount = ((firstWeekday + days + 6) ~/ 7) * 7;
    const weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 2, 16, 18), children: [
      _surface(child: Column(children: [
        Row(children: [
          IconButton(onPressed: () => onMonthChanged(DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left_rounded, color: _green)),
          Expanded(child: Text('${_monthName(month.month)} ${month.year}', textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 20, color: _green, fontWeight: FontWeight.w700))),
          IconButton(onPressed: () => onMonthChanged(DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right_rounded, color: _green)),
        ]),
        Row(children: weekdayLabels.map((day) => Expanded(child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text(day, style: const TextStyle(color: Color(0xFF77796F), fontSize: 12, fontWeight: FontWeight.w600)))))).toList()),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3),
          itemBuilder: (context, index) {
            final number = index - firstWeekday + 1;
            if (number < 1 || number > days) return const SizedBox.shrink();
            final chosen = selectedDay?.year == month.year && selectedDay?.month == month.month && selectedDay?.day == number;
            final hasEntry = entryDays.contains(number);
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onDaySelected(DateTime(month.year, month.month, number)),
              child: Container(
                decoration: BoxDecoration(color: chosen ? _green : hasEntry ? _sage : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$number', style: TextStyle(color: chosen ? Colors.white : _ink, fontWeight: hasEntry ? FontWeight.w700 : FontWeight.w400)),
                  if (hasEntry) Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 2), decoration: BoxDecoration(color: chosen ? Colors.white : _green, shape: BoxShape.circle)),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 9),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.circle, size: 8, color: _green), SizedBox(width: 6), Text('You wrote in your journal', style: TextStyle(color: Color(0xFF77796F), fontSize: 11))]),
      ])),
      const SizedBox(height: 12),
      Text(selectedDay == null ? 'Choose a day' : _dateLabel(selectedDay), style: GoogleFonts.playfairDisplay(fontSize: 18, color: _green, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      if (selectedDay != null && selectedEntries.isEmpty) const Text('No entries for this day.', style: TextStyle(color: Color(0xFF77796F))),
      for (final entry in selectedEntries) Padding(padding: const EdgeInsets.only(bottom: 8), child: _surface(onTap: () => onOpen(entry), child: Row(children: [const Icon(Icons.menu_book_rounded, color: _green), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.title.isEmpty ? 'Untitled entry' : entry.title, style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700)), Text(entry.body.replaceAll('\n', ' '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))])), const Icon(Icons.chevron_right_rounded)]))),
    ]);
  }
}

class SavedJournalEntryScreen extends StatefulWidget {
  const SavedJournalEntryScreen({required this.journal, required this.entry, required this.entries, required this.index, super.key});
  final PrivateJournalService journal;
  final PrivateJournalEntry entry;
  final List<PrivateJournalEntry> entries;
  final int index;

  @override
  State<SavedJournalEntryScreen> createState() => _SavedJournalEntryScreenState();
}

class _SavedJournalEntryScreenState extends State<SavedJournalEntryScreen> {
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    _favorite = widget.entry.favorite;
  }

  Future<void> _toggleFavorite() async {
    try {
      await widget.journal.setFavorite(widget.entry.id, !_favorite);
      if (mounted) setState(() => _favorite = !_favorite);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update favorite.')));
    }
  }

  Future<void> _edit() async {
    final draft = PrivateJournalDraft(title: widget.entry.title, body: widget.entry.body, tags: widget.entry.tags, attachments: widget.entry.attachments, entryId: widget.entry.id);
    await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => WriteFreelyEditorScreen(journal: widget.journal, draft: draft, entry: widget.entry)));
  }

  Future<void> _copy() async {
    final text = [if (widget.entry.title.isNotEmpty) widget.entry.title, widget.entry.body].join('\n\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry copied.')));
  }

  Future<void> _delete() async {
    final deleted = await _confirmDelete(context, widget.journal, widget.entry);
    if (deleted && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => MyEntriesScreen(journal: widget.journal)));
    }
  }

  Future<void> _move(int delta) async {
    final next = widget.index + delta;
    if (next < 0 || next >= widget.entries.length) return;
    final entry = widget.entries[next];
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => SavedJournalEntryScreen(journal: widget.journal, entry: entry, entries: widget.entries, index: next)));
  }

  int _streak() {
    final days = widget.entries.map((entry) => entry.createdAt).whereType<DateTime>().map((date) => DateTime(date.year, date.month, date.day)).toSet();
    if (days.isEmpty) return 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final streak = _streak();
    final wide = MediaQuery.sizeOf(context).width > 720;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _green,
        leading: IconButton(tooltip: 'My Entries', icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: Text('My Journal', style: GoogleFonts.playfairDisplay(color: _green, fontWeight: FontWeight.w600)),
        actions: [TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MyEntriesScreen(journal: widget.journal))), child: const Text('My Entries', style: TextStyle(color: _green))), const SizedBox(width: 6)],
      ),
      body: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 760 : 650),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 5, 16, 24), children: [
          _WriteFreelyBanner(height: 145),
          const SizedBox(height: 12),
          _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.title.trim().isEmpty ? (entry.prompt.trim().isEmpty ? 'A page from your journal' : entry.prompt) : entry.title, style: GoogleFonts.playfairDisplay(fontSize: 25, color: _green, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_dateLabel(entry.createdAt, includeTime: true), style: const TextStyle(color: Color(0xFF73776E), fontSize: 12)),
              ])),
              IconButton(tooltip: 'Edit entry', onPressed: _edit, icon: const Icon(Icons.edit_outlined, color: _green)),
            ]),
            const SizedBox(height: 16),
            JournalFormattedBody(body: entry.body),
            if (entry.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: entry.attachments.map((path) => _AttachmentTile(path: path, journal: widget.journal, readOnly: true)).toList()),
            ],
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(spacing: 6, runSpacing: 5, children: entry.tags.map(_tag).toList()),
            ],
            const Divider(height: 24, color: _line),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _entryAction(Icons.edit_outlined, 'Edit', _edit),
              _entryAction(_favorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, _favorite ? 'Saved' : 'Favorite', _toggleFavorite),
              _entryAction(Icons.copy_rounded, 'Copy', _copy),
              _entryAction(Icons.delete_outline_rounded, 'Delete', _delete),
            ]),
          ])),
          const SizedBox(height: 11),
          Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: widget.index + 1 < widget.entries.length ? () => _move(1) : null, icon: const Icon(Icons.arrow_back_rounded), label: const Text('Previous Entry'), style: OutlinedButton.styleFrom(foregroundColor: _green, side: const BorderSide(color: _line), padding: const EdgeInsets.symmetric(vertical: 13)))),
            const SizedBox(width: 9),
            Expanded(child: OutlinedButton.icon(onPressed: widget.index > 0 ? () => _move(-1) : null, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Next Entry'), iconAlignment: IconAlignment.end, style: OutlinedButton.styleFrom(foregroundColor: _green, side: const BorderSide(color: _line), padding: const EdgeInsets.symmetric(vertical: 13)))),
          ]),
          if (streak > 1) ...[
            const SizedBox(height: 11),
            _surface(child: Row(children: [const Icon(Icons.spa_rounded, size: 30, color: _green), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Journal streak', style: GoogleFonts.playfairDisplay(fontSize: 18, color: _green, fontWeight: FontWeight.w700)), Text('$streak days in a row · Based on your saved entries', style: const TextStyle(color: Color(0xFF62675E), fontSize: 12))]))])),
          ],
        ]),
      )),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 10), child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? 728 : 618), child: OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MyEntriesScreen(journal: widget.journal))), icon: const Icon(Icons.menu_book_rounded), label: const Text('Return to My Entries'), style: OutlinedButton.styleFrom(foregroundColor: _green, side: const BorderSide(color: _line), padding: const EdgeInsets.symmetric(vertical: 13))))))),
    );
  }
}

class JournalFormattedBody extends StatefulWidget {
  const JournalFormattedBody({required this.body, super.key});
  final String body;

  @override
  State<JournalFormattedBody> createState() => _JournalFormattedBodyState();
}

class _JournalFormattedBodyState extends State<JournalFormattedBody> {
  final List<TapGestureRecognizer> _recognizers = [];
  static final RegExp _tokens = RegExp(r'(\*\*[^*]+\*\*|_[^_]+_|\[[^\]]+\]\(https?://[^)]+\))');

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  List<InlineSpan> _spans(String line) {
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final match in _tokens.allMatches(line)) {
      if (match.start > offset) spans.add(TextSpan(text: line.substring(offset, match.start)));
      final token = match.group(0)!;
      if (token.startsWith('**')) {
        spans.add(TextSpan(text: token.substring(2, token.length - 2), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (token.startsWith('_')) {
        spans.add(TextSpan(text: token.substring(1, token.length - 1), style: const TextStyle(fontStyle: FontStyle.italic)));
      } else {
        final separator = token.indexOf('](');
        final label = token.substring(1, separator);
        final url = token.substring(separator + 2, token.length - 1);
        final recognizer = TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        _recognizers.add(recognizer);
        spans.add(TextSpan(text: label, style: const TextStyle(color: _green, decoration: TextDecoration.underline), recognizer: recognizer));
      }
      offset = match.end;
    }
    if (offset < line.length) spans.add(TextSpan(text: line.substring(offset)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    final lines = widget.body.split('\n');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < lines.length; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i == lines.length - 1 ? 0 : 10),
          child: lines[i].startsWith('• ')
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('•  ', style: TextStyle(fontSize: 16, color: _green)), Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: _ink, fontSize: 16, height: 1.65), children: _spans(lines[i].substring(2)))))])
              : RichText(text: TextSpan(style: const TextStyle(color: _ink, fontSize: 16, height: 1.65), children: _spans(lines[i]))),
        ),
    ]);
  }
}

class _WriteFreelyBanner extends StatelessWidget {
  const _WriteFreelyBanner({this.height = 132});
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/images/my_space_hero.jpg', fit: BoxFit.cover, alignment: Alignment.center),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, stops: [.05, .5, 1], colors: [Color(0xFFFFF8EC), Color(0xDFFFF8EC), Color(0x00FFF8EC)]))),
            Padding(padding: const EdgeInsets.fromLTRB(15, 12, 12, 10), child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 255, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Write freely.', style: GoogleFonts.playfairDisplay(color: _green, fontWeight: FontWeight.w700, fontSize: 25)),
              const Text('Let your thoughts flow, no rules, no pressure.', style: TextStyle(color: _ink, fontSize: 13, height: 1.25)),
              const SizedBox(height: 5),
              const Row(children: [Icon(Icons.lock_rounded, color: _green, size: 13), SizedBox(width: 5), Flexible(child: Text('Your journal is private by default.', maxLines: 2, style: TextStyle(color: _ink, fontSize: 10.5, height: 1.1)))]),
            ])))),
          ]),
        ),
      );
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.path, required this.journal, this.onRemove, this.readOnly = false});
  final String path;
  final PrivateJournalService journal;
  final VoidCallback? onRemove;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
        future: journal.loadImage(path),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          return Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: 92, height: 76, color: _sage, child: bytes == null ? const Icon(Icons.image_outlined, color: _green) : Image.memory(bytes, fit: BoxFit.cover, width: 92, height: 76))),
            if (!readOnly && onRemove != null) Positioned(right: 1, top: 1, child: Material(color: Colors.white.withValues(alpha: .9), shape: const CircleBorder(), child: InkWell(onTap: onRemove, customBorder: const CircleBorder(), child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.close_rounded, size: 16, color: _ink))))),
          ]);
        },
      );
}

Widget _surface({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(14), VoidCallback? onTap}) {
  return Material(
    color: _paper,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFF0E8DC)), boxShadow: const [BoxShadow(color: Color(0x0A46351A), blurRadius: 10, offset: Offset(0, 3))]),
        child: child,
      ),
    ),
  );
}

Widget _tag(String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(20)), child: Text(label, style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w500)));

Widget _entryAction(IconData icon, String label, VoidCallback action) => TextButton.icon(onPressed: action, icon: Icon(icon, size: 19), label: Text(label), style: TextButton.styleFrom(foregroundColor: _ink));

String _monthName(int month) => const ['January','February','March','April','May','June','July','August','September','October','November','December'][month - 1];

Future<bool> _confirmDelete(BuildContext context, PrivateJournalService journal, PrivateJournalEntry entry) async {
  final confirm = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
    backgroundColor: _paper,
    title: const Text('Delete this entry?'),
    content: const Text('This permanently removes the entry and cannot be undone.'),
    actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep entry')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(backgroundColor: _green), child: const Text('Delete'))],
  ));
  if (confirm != true) return false;
  try {
    await journal.deleteEntry(entry.id);
    for (final path in entry.attachments) {
      try { await journal.deleteImage(path); } catch (_) { /* entry is already securely removed */ }
    }
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted.')));
    return true;
  } catch (_) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry was not deleted. Please try again.')));
    return false;
  }
}
