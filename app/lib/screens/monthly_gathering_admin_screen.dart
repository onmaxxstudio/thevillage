import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';

class MonthlyGatheringAdminScreen extends StatefulWidget {
  const MonthlyGatheringAdminScreen({super.key});
  @override
  State<MonthlyGatheringAdminScreen> createState() => _MonthlyGatheringAdminScreenState();
}

class _MonthlyGatheringAdminScreenState extends State<MonthlyGatheringAdminScreen> {
  final title = TextEditingController(text: 'Letting Go & Starting Fresh'), description = TextEditingController(text: 'A guided experience to release what no longer serves you and step intentionally into your next chapter.'), expectations = TextEditingController(), meeting = TextEditingController();
  DateTime? startsAt;
  bool published = false, plus = true, canceled = false, saving = false;
  String imageUrl = ''; String? eventId; String? recordingPath;
  @override
  void dispose() { title.dispose(); description.dispose(); expectations.dispose(); meeting.dispose(); super.dispose(); }
  Future<void> _load(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data(); eventId = doc.id;
    title.text = (data['title'] ?? '').toString(); description.text = (data['description'] ?? '').toString();
    expectations.text = (data['whatToExpect'] ?? '').toString(); imageUrl = (data['imageUrl'] ?? '').toString();
    startsAt = (data['startsAt'] as Timestamp?)?.toDate(); published = data['published'] == true;
    canceled = data['status'] == 'canceled'; plus = data['access'] != 'free';
    try { final private = await doc.reference.collection('private').doc('details').get();
      meeting.text = (private.data()?['meetingUrl'] ?? '').toString(); recordingPath = private.data()?['recordingPath']?.toString();
    } catch (_) { meeting.clear(); }
    if (mounted) setState(() {});
  }
  Future<void> _upload(bool recording) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final file = recording ? await ImagePicker().pickVideo(source: ImageSource.gallery) : await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > (recording ? 50 : 8) * 1024 * 1024) { _notice('File is too large.'); return; }
    try {
      if (recording && eventId == null) { _notice('Save the draft before uploading a recording.'); return; }
      final path = recording ? 'monthly_recordings/$eventId/${DateTime.now().millisecondsSinceEpoch}.mp4' : 'admin_content/${user.uid}/monthly_gathering/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: recording ? 'video/mp4' : 'image/jpeg'));
      if (!mounted) return;
      if (recording) { recordingPath = path; } else { imageUrl = await ref.getDownloadURL(); }
      setState(() {});
      _notice('Uploaded. Save the event to publish this change.');
    } catch (_) { _notice('Upload failed.'); }
  }
  void _notice(String value) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value))); }
  Future<void> _sendReminder() async {
    if (eventId == null) return;
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'us-east1')
          .httpsCallable('sendMonthlyGatheringReminder')
          .call<Map<String, dynamic>>({'eventId':eventId, 'label': canceled ? 'canceled' : 'rescheduled'});
      _notice('Reminder sent to ${result.data['delivered']} registered members.');
    } catch (_) { _notice('Could not send reminders. Check the deployed reminder function.'); }
  }
  Future<void> _save() async {
    if (title.text.trim().isEmpty || description.text.trim().isEmpty) { _notice('Add a title and description.'); return; }
    if (published && (startsAt == null || meeting.text.trim().isEmpty)) { _notice('Confirm the date, time, and meeting link before publishing.'); return; }
    if (meeting.text.isNotEmpty && Uri.tryParse(meeting.text)?.scheme != 'https') { _notice('Meeting link must use HTTPS.'); return; }
    setState(() => saving = true);
    try {
      final collection = FirebaseFirestore.instance.collection('admin_events');
      final ref = eventId == null ? collection.doc() : collection.doc(eventId);
      final batch = FirebaseFirestore.instance.batch();
      batch.set(ref, {'kind':'monthly_gathering', 'title':title.text.trim(), 'description':description.text.trim(), 'whatToExpect': expectations.text.trim(),
        'imageUrl':imageUrl, 'startsAt':startsAt == null ? null : Timestamp.fromDate(startsAt!), 'durationMinutes':60,
        'access':plus ? 'plus' : 'free', 'published':published, 'status':canceled ? 'canceled' : 'scheduled',
        'recordingAvailable':recordingPath != null, 'updatedAt':FieldValue.serverTimestamp(), 'sortOrder':DateTime.now().millisecondsSinceEpoch}, SetOptions(merge:true));
      batch.set(ref.collection('private').doc('details'), {'meetingUrl':meeting.text.trim(), 'recordingPath':recordingPath ?? ''}, SetOptions(merge:true));
      await batch.commit(); eventId = ref.id; _notice('Event saved.');
    } catch (_) { _notice('Could not save the event. Check admin access.'); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manage Monthly Gathering')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('admin_events').snapshots(), builder: (context, snapshot) {
      final docs = snapshot.data?.docs.where((doc) => doc.data()['kind'] == 'monthly_gathering').toList() ?? [];
      return ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Choose an event to edit, or create a new one.'),
        Wrap(spacing: 8, children: [ActionChip(label: const Text('New event'), onPressed: () => setState(() { eventId = null; title.clear(); description.clear(); expectations.clear(); meeting.clear(); imageUrl = ''; recordingPath = null; startsAt = null; published = false; canceled = false; plus = true; })),
          for (final doc in docs) ActionChip(label: Text(doc.data()['title']?.toString() ?? 'Event'), onPressed: () => _load(doc))]),
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
        TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
        TextField(controller: expectations, maxLines: 2, decoration: const InputDecoration(labelText: 'What to Expect')),
        TextField(controller: meeting, decoration: const InputDecoration(labelText: 'Private meeting link (HTTPS)')),
        ListTile(title: Text(startsAt == null ? 'Set date and time' : startsAt!.toLocal().toString()), trailing: const Icon(Icons.calendar_today), onTap: () async {
          final date = await showDatePicker(context: context, initialDate: startsAt ?? DateTime.now(), firstDate: DateTime(2026), lastDate: DateTime(2035));
          if (date == null || !context.mounted) return;
          final time = await showTimePicker(context: context, initialTime: startsAt == null ? TimeOfDay.now() : TimeOfDay.fromDateTime(startsAt!));
          if (time != null) setState(() => startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
        }),
        TextButton(onPressed: () => _upload(false), child: Text(imageUrl.isEmpty ? 'Upload cover image' : 'Replace cover image')),
        if (eventId != null) TextButton(onPressed: () => _upload(true), child: Text(recordingPath == null ? 'Upload recording' : 'Replace recording')),
        SwitchListTile(title: const Text('Village Plus Exclusive'), value: plus, onChanged: (value) => setState(() => plus = value)),
        SwitchListTile(title: const Text('Canceled'), value: canceled, onChanged: (value) => setState(() => canceled = value)),
        SwitchListTile(title: const Text('Publish'), subtitle: const Text('Requires confirmed date, time, and meeting link.'), value: published, onChanged: (value) => setState(() => published = value)),
        FilledButton(onPressed: saving ? null : _save, child: const Text('Save Event')),
        if (eventId != null) TextButton(onPressed: _sendReminder, child: Text(canceled ? 'Notify members of cancellation' : 'Notify members of new event details')),
        if (eventId != null) StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('admin_events').doc(eventId).collection('registrations').snapshots(), builder: (context, registrations) {
          final members = registrations.data?.docs ?? [];
          final joined = members.where((doc) => doc.data()['joinedAt'] != null).length;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reservations: ${members.length} • Join clicks: $joined'),
            for (final member in members) ListTile(dense: true, title: Text(member.id),
              subtitle: Text(member.data()['joinedAt'] == null ? 'Reserved' : 'Opened live event')),
          ]);
        }),
      ]);
    }),
  );
}
