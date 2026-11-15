@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:ask_the_village/screens/circle_screen.dart';
import 'package:ask_the_village/services/circle_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

Future<void> loadSdk() async {
  final ready = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src = 'http://127.0.0.1:8765/avatar-firebase-sdk.js';
  script.addEventListener('load', ((web.Event _) => ready.complete()).toJS);
  script.addEventListener(
    'error',
    ((web.Event _) => ready.completeError(
      StateError('Test SDK did not load'),
    )).toJS,
  );
  web.document.head!.appendChild(script);
  await ready.future.timeout(const Duration(seconds: 20));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Circle chat works between members at phone, tablet and desktop sizes',
    (tester) async {
      const options = FirebaseOptions(
        apiKey: 'emulator-key',
        appId: '1:123:web:chat',
        messagingSenderId: '123',
        projectId: 'demo-village',
      );
      const password = 'local-emulator-test-password';
      await tester.runAsync(() async {
        globalContext['flutterfire_web_sdk_version'] = '12.19.0'.toJS;
        await loadSdk();
        FirebaseCoreWeb.registerWith(webPluginRegistrar);
        FirebaseAuthWeb.registerWith(webPluginRegistrar);
        FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
        SharedPreferencesPlugin.registerWith(webPluginRegistrar);
        await Firebase.initializeApp(options: options);
      });
      final auth = FirebaseAuth.instance;
      final db = FirebaseFirestore.instance;
      final service = CircleService();
      late String aliceUid;
      late String bobUid;
      late FirebaseFirestore peerDb;
      await tester.runAsync(() async {
        await auth.useAuthEmulator('127.0.0.1', 9099);
        db.useFirestoreEmulator('127.0.0.1', 8080);
        final alice = await auth.createUserWithEmailAndPassword(
          email: 'circle-alice@example.test',
          password: password,
        );
        aliceUid = alice.user!.uid;
        await alice.user!.updateDisplayName('ChatAlice');
        await auth.signOut();
        final bob = await auth.createUserWithEmailAndPassword(
          email: 'circle-bob@example.test',
          password: password,
        );
        bobUid = bob.user!.uid;
        await bob.user!.updateDisplayName('ChatBob');
        await service.sendRequest(
          CirclePerson(uid: aliceUid, username: 'ChatAlice'),
        );
        await auth.signOut();
        await auth.signInWithEmailAndPassword(
          email: 'circle-alice@example.test',
          password: password,
        );
        await service.acceptRequest(
          CircleRequest(
            sender: CirclePerson(uid: bobUid, username: 'ChatBob'),
            createdAt: DateTime.now(),
          ),
        );
        final peer = await Firebase.initializeApp(
          name: 'chat-peer',
          options: options,
        );
        final peerAuth = FirebaseAuth.instanceFor(app: peer);
        peerDb = FirebaseFirestore.instanceFor(app: peer);
        await peerAuth.useAuthEmulator('127.0.0.1', 9099);
        peerDb.useFirestoreEmulator('127.0.0.1', 8080);
        await peerAuth.signInWithEmailAndPassword(
          email: 'circle-bob@example.test',
          password: password,
        );
        // Existing histories larger than the former 100-message limit remain visible.
        final batch = db.batch();
        for (var i = 0; i < 105; i++) {
          batch.set(
            db
                .collection('conversations')
                .doc(service.conversationId(bobUid))
                .collection('messages')
                .doc('history-$i'),
            {
              'senderUid': aliceUid,
              'recipientUid': bobUid,
              'text': 'History $i',
              'createdAt': FieldValue.serverTimestamp(),
              'readAt': null,
            },
          );
        }
        await batch.commit();
        expect((await service.messages(bobUid).first).length, 105);
      });

      const legacyKey = r'ask_the_village_circle_messages_$uid';
      const legacyCache = [
        '{"memberName":"@OtherMember","text":"Unassigned legacy history","createdAt":"2026-01-01T00:00:00Z"}',
      ];
      await tester.runAsync(
        () => SharedPreferencesAsync().setStringList(legacyKey, legacyCache),
      );

      Future<void> visible(Finder finder) async {
        for (var i = 0; i < 160 && finder.evaluate().isEmpty; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)),
          );
          await tester.pump(const Duration(milliseconds: 40));
        }
        expect(finder, findsWidgets);
        await tester.ensureVisible(finder.first);
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> tapText(String value) async {
        debugPrint('Chat test action: $value');
        final finder = find.text(value);
        await visible(finder);
        for (
          var i = 0;
          i < 160 && finder.hitTestable().evaluate().isEmpty;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)),
          );
          await tester.pump(const Duration(milliseconds: 40));
        }
        expect(finder.hitTestable(), findsWidgets);
        await tester.tap(finder.hitTestable().first);
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> dismiss() async {
        await tester.tapAt(const Offset(4, 4));
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> peerSend(String text) async {
        await tester.runAsync(() async {
          final conversation = peerDb
              .collection('conversations')
              .doc(service.conversationId(bobUid));
          final batch = peerDb.batch();
          batch.set(conversation, {
            'members': [aliceUid, bobUid]..sort(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          batch.set(conversation.collection('messages').doc(), {
            'senderUid': bobUid,
            'recipientUid': aliceUid,
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
            'readAt': null,
          });
          await batch.commit();
        });
      }

      for (final size in [
        const Size(390, 844),
        const Size(768, 1024),
        const Size(1440, 1000),
      ]) {
        debugPrint('Chat test viewport: $size');
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(const MaterialApp(home: CircleScreen()));
        await tester.pump(const Duration(milliseconds: 400));
        await tapText('Circle chats');
        await peerSend('Unread ${size.width}');
        await visible(find.byIcon(Icons.mark_chat_unread_rounded));
        await tapText('@ChatBob');
        await visible(find.text('Messages between you'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text('History 104'),
          240,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 100,
        );
        await tester.scrollUntilVisible(
          find.text('Message'),
          -240,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 100,
        );
        await tapText('Message');
        await tapText('Send Private Message');
        await visible(find.text('Write a message first.'));
        final sent = 'UI message ${size.width}';
        await tester.enterText(find.byType(TextField).last, sent);
        await tapText('Send Private Message');
        // Give the SDK time to acknowledge the write before selecting the member again.
        await tester.runAsync(() async {
          await service
              .messages(bobUid)
              .firstWhere((items) => items.any((m) => m.text == sent))
              .timeout(const Duration(seconds: 10));
        });
        for (
          var i = 0;
          i < 160 && find.text('Message @ChatBob').evaluate().isNotEmpty;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)),
          );
          await tester.pump(const Duration(milliseconds: 40));
        }
        expect(find.text('Message @ChatBob'), findsNothing);
        await tester.pump(const Duration(milliseconds: 500));
        await tapText('@ChatBob');
        await visible(find.text(sent));
        final reply = 'Live reply ${size.width}';
        await peerSend(reply);
        await visible(find.text(reply));
        await dismiss();
        await tapText('@ChatBob');
        await tapText('Check In');
        await tapText('Thinking of you');
        await tester.runAsync(() async {
          await service
              .messages(bobUid)
              .firstWhere(
                (items) => items.any((m) => m.text == 'Thinking of you'),
              )
              .timeout(const Duration(seconds: 10));
        });
        await tester.pump(const Duration(milliseconds: 400));
        await tapText('@ChatBob');
        await tapText('Remove from Circle');
        await tapText('Cancel');
        await tester.pageBack();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.runAsync(() async {
        final cache = SharedPreferencesAsync();
        final aliceCache = await cache.getStringList(
          'ask_the_village_circle_messages_$aliceUid',
        );
        expect(aliceCache, isNotNull);
        expect(
          aliceCache!.where((item) => item.contains('UI message ')).length,
          3,
        );
        expect(
          await cache.getStringList('ask_the_village_circle_messages_$bobUid'),
          isNull,
        );
        expect(await cache.getStringList(legacyKey), legacyCache);
        await auth.signOut();
        await auth.signInWithEmailAndPassword(
          email: 'circle-alice@example.test',
          password: password,
        );
        final history = await service.messages(bobUid).first;
        expect(
          history.where((m) => m.text.startsWith('UI message ')).length,
          3,
        );
        expect(
          history.where((m) => m.text.startsWith('Live reply ')).length,
          3,
        );
        expect(history.where((m) => m.text.startsWith('History ')).length, 105);
        await service.markMessagesRead(bobUid);
        expect(
          (await service.messages(bobUid).first).where(
            (m) => m.recipientUid == aliceUid && m.readAt == null,
          ),
          isEmpty,
        );
      });
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
