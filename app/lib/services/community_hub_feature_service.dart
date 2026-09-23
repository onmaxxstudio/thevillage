import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class CommunityHubFeatures {
  const CommunityHubFeatures({
    this.spotlightId = '',
    this.pulsePostIds = const [],
    this.resourceId = '',
    this.eventId = '',
    this.communityOrder = const [],
  });

  final String spotlightId;
  final List<String> pulsePostIds;
  final String resourceId;
  final String eventId;
  final List<String> communityOrder;

  factory CommunityHubFeatures.fromMap(Map<String, dynamic> data) =>
      CommunityHubFeatures(
        spotlightId: (data['spotlightId'] ?? '').toString(),
        pulsePostIds: (data['pulsePostIds'] as List<dynamic>? ?? const [])
            .map((id) => id.toString())
            .take(2)
            .toList(),
        resourceId: (data['resourceId'] ?? '').toString(),
        eventId: (data['eventId'] ?? '').toString(),
        communityOrder: (data['communityOrder'] as List<dynamic>? ?? const [])
            .map((id) => id.toString())
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'spotlightId': spotlightId,
        'pulsePostIds': pulsePostIds.take(2).toList(),
        'resourceId': resourceId,
        'eventId': eventId,
        'communityOrder': communityOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class CommunityHubFeatureService {
  bool get cloudReady => Firebase.apps.isNotEmpty;

  DocumentReference<Map<String, dynamic>> get _document =>
      FirebaseFirestore.instance.collection('admin_resources').doc('hub_features');

  Stream<CommunityHubFeatures> watch() {
    if (!cloudReady) return Stream.value(const CommunityHubFeatures());
    return _document.snapshots().map((snapshot) =>
        CommunityHubFeatures.fromMap(snapshot.data() ?? const {}));
  }

  Future<void> save(CommunityHubFeatures features) =>
      _document.set({
        ...features.toMap(),
        'published': true,
        'kind': 'hub_config',
        'sortOrder': 0,
      }, SetOptions(merge: true));
}
