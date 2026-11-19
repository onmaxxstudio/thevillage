#!/usr/bin/env node
/**
 * One-time admin import for the approved 365-question CSV/JSON bank.
 * Run only from a trusted workstation with Firebase Admin credentials.
 * Requires: npm install --no-save firebase-admin
 * Usage: GOOGLE_APPLICATION_CREDENTIALS=/secure/service-account.json node scripts/import_daily_village_questions.cjs /path/to/ask_the_village_365_question_bank.json
 * DRY RUN (default): set APPLY=1 to write after reviewing output.
 * Existing question documents are never overwritten.
 */
const fs = require('node:fs');
const path = process.argv[2];
if (!path) throw new Error('Provide the 365-question JSON bank path.');
const input = JSON.parse(fs.readFileSync(path, 'utf8'));
const questions = Array.isArray(input) ? input : input.questions;
if (!Array.isArray(questions) || questions.length !== 365) throw new Error('Expected exactly 365 questions.');
const ids = new Set();
for (const [index, q] of questions.entries()) {
  if (q.day !== index + 1 || typeof q.question !== 'string' || !q.question.trim() ||
      !/^\d{4}-\d{2}-\d{2}$/.test(q.suggestedDate || '')) {
    throw new Error('Invalid question entry at index ' + index);
  }
  if (ids.has(q.suggestedDate)) throw new Error('Duplicate date ' + q.suggestedDate);
  ids.add(q.suggestedDate);
}
(async () => {
  if (process.env.APPLY !== '1') {
    console.log('DRY RUN: ' + questions.length + ' questions validated; no writes.');
    return;
  }
  const admin = require('firebase-admin');
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: 'the-village-d7af4' });
  const db = admin.firestore();
  let written = 0, skipped = 0;
  for (const q of questions) {
    // 00:00 America/New_York; DST-aware using Intl without extra dependencies.
    const middayUtc = new Date(q.suggestedDate + 'T12:00:00Z');
    const easternHour = Number(new Intl.DateTimeFormat('en-US', {
      timeZone: 'America/New_York', hour: '2-digit', hourCycle: 'h23',
    }).format(middayUtc));
    const offsetHours = 12 - easternHour;
    const publishAt = new Date(Date.parse(q.suggestedDate + 'T00:00:00Z') + offsetHours * 3600000);
    const ref = db.collection('village_daily_questions').doc(q.suggestedDate);
    if (process.env.APPLY === '1') {
      const existing = await ref.get();
      if (existing.exists) { skipped++; continue; }
      await ref.create({
        date: q.suggestedDate,
        day: q.day,
        category: q.category || 'community',
        question: q.question.trim(),
        conversationPrompt: q.conversationPrompt || '',
        publishAt: admin.firestore.Timestamp.fromDate(publishAt),
        status: 'published',
        importedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      written++;
    } else {
      console.log(q.suggestedDate + ' -> ' + publishAt.toISOString() + ' ' + q.question);
    }
  }
  console.log(process.env.APPLY === '1'
    ? 'Imported ' + written + ', skipped existing ' + skipped
    : 'DRY RUN: ' + questions.length + ' questions validated; no writes. Set APPLY=1 to import.');
})().catch(e => { console.error(e); process.exitCode = 1; });
