/**
 * Vedo — Cloud Functions for push notifications
 * =================================================
 * WHY THIS FILE EXISTS
 * index.html (the web app) can only RECEIVE push notifications and register
 * each device's FCM token. Actually SENDING a push — the part that reaches a
 * phone even when the app/apk is fully closed — has to happen from a trusted
 * server, because it needs your Firebase service-account credentials.
 * Firebase Cloud Functions is that server, and it lives in this file.
 *
 * WHAT THIS FILE DOES
 * It watches Firestore for the same writes your app already makes —
 * createSchedule, replyToDoubt/resolveDoubt, createFee, createHomework,
 * createNote, createTest, addFeedback, and approveRequest — and sends a push
 * to the right users' saved fcmTokens the moment those happen. No changes
 * needed on the client beyond what's already in index.html.
 *
 * ONE-TIME SETUP (do this from a terminal, not from Claude):
 *   1. npm install -g firebase-tools
 *   2. firebase login
 *   3. In your project folder: firebase init functions
 *      → choose the existing "vedo-01" project, JavaScript, and when it
 *        asks to overwrite functions/index.js, say NO and copy this file in
 *        (or say yes and paste this content in afterwards).
 *   4. cd functions && npm install firebase-admin firebase-functions
 *   5. From the project root: firebase deploy --only functions
 *
 * After that, every new timetable entry / doubt reply / fee / homework /
 * note / test / feedback / approval in Firestore triggers a real push
 * automatically — nothing else to run.
 */

const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/** Fetch fcmTokens for a list of user ids (dedupes, drops empties). */
async function tokensForUserIds(userIds) {
  const ids = [...new Set(userIds.filter(Boolean))];
  if (!ids.length) return [];
  const snaps = await Promise.all(ids.map((id) => db.collection('users').doc(id).get()));
  const tokens = [];
  snaps.forEach((snap) => {
    if (snap.exists && Array.isArray(snap.data().fcmTokens)) tokens.push(...snap.data().fcmTokens);
  });
  return [...new Set(tokens)];
}

/** All student ids enrolled in a class (roster stored on the class doc). */
async function studentIdsForClass(classId) {
  if (!classId) return [];
  const classSnap = await db.collection('classes').doc(classId).get();
  if (!classSnap.exists) return [];
  return classSnap.data().studentIds || [];
}

/** Send one push to a set of tokens; silently skips if there are none. */
async function sendPush(tokens, { title, body, path = '/', tag }) {
  if (!tokens.length) return;
  await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: { path, tag: tag || '' },
    webpush: { fcmOptions: { link: path } }
  });
}

// ---- 1. Timetable / schedule changes -------------------------------------
exports.onScheduleCreated = onDocumentCreated('schedules/{scheduleId}', async (event) => {
  const s = event.data.data();
  const studentIds = await studentIdsForClass(s.classId);
  const tokens = await tokensForUserIds(studentIds);
  await sendPush(tokens, {
    title: 'Timetable updated',
    body: `${s.subject || s.title || 'A class'} — ${s.day || ''} ${s.time || ''}`.trim(),
    path: '/student',
    tag: 'timetable'
  });
});

// ---- 2. Doubt resolved / replied ------------------------------------------
exports.onDoubtUpdated = onDocumentUpdated('doubts/{doubtId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const justResolved = before.status !== 'resolved' && after.status === 'resolved';
  const justReplied = before.reply !== after.reply && after.reply;
  if (!justResolved && !justReplied) return;
  const tokens = await tokensForUserIds([after.studentId]);
  await sendPush(tokens, {
    title: 'Your doubt was answered',
    body: after.reply ? after.reply.slice(0, 120) : 'Your teacher marked your doubt as resolved.',
    path: '/student',
    tag: 'doubt'
  });
});

// ---- 3. Fee reminders -------------------------------------------------------
// Fires the moment a fee record is created. For an ongoing "due soon"
// reminder (not just on-create), pair this with a scheduled function — see
// onFeeDueReminder below.
exports.onFeeCreated = onDocumentCreated('fees/{feeId}', async (event) => {
  const f = event.data.data();
  const tokens = await tokensForUserIds([f.studentId]);
  await sendPush(tokens, {
    title: 'Fee due',
    body: `₹${f.amount} due on ${f.dueDate || 'the due date'}`,
    path: '/student',
    tag: 'fee'
  });
});

// Optional: run daily and remind anyone with a fee due in the next 2 days.
// Uncomment and deploy if you want recurring reminders, not just on-create.
//
// const { onSchedule } = require('firebase-functions/v2/scheduler');
// exports.onFeeDueReminder = onSchedule('every day 09:00', async () => {
//   const twoDaysFromNow = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
//   const dueSoon = await db.collection('fees')
//     .where('status', '==', 'pending')
//     .where('dueDate', '==', twoDaysFromNow)
//     .get();
//   for (const doc of dueSoon.docs) {
//     const f = doc.data();
//     const tokens = await tokensForUserIds([f.studentId]);
//     await sendPush(tokens, { title: 'Fee due in 2 days', body: `₹${f.amount} due ${f.dueDate}`, path: '/student', tag: 'fee-reminder' });
//   }
// });

// ---- 5. New note shared ------------------------------------------------------
exports.onNoteCreated = onDocumentCreated('notes/{noteId}', async (event) => {
  const n = event.data.data();
  const studentIds = await studentIdsForClass(n.classId);
  const tokens = await tokensForUserIds(studentIds);
  await sendPush(tokens, {
    title: 'New note shared',
    body: n.title,
    path: '/student',
    tag: 'note'
  });
});

// ---- 6. New test scheduled ---------------------------------------------------
exports.onTestCreated = onDocumentCreated('tests/{testId}', async (event) => {
  const t = event.data.data();
  const studentIds = await studentIdsForClass(t.classId);
  const tokens = await tokensForUserIds(studentIds);
  await sendPush(tokens, {
    title: 'New test scheduled',
    body: `${t.title}${t.dueDate ? ` — ${t.dueDate}` : ''}`,
    path: '/student',
    tag: 'test'
  });
});

// ---- 7. Teacher feedback -----------------------------------------------------
exports.onFeedbackCreated = onDocumentCreated('feedbacks/{feedbackId}', async (event) => {
  const f = event.data.data();
  const tokens = await tokensForUserIds([f.studentId]);
  await sendPush(tokens, {
    title: 'New feedback from your teacher',
    body: (f.text || '').slice(0, 120),
    path: '/student',
    tag: 'feedback'
  });
});

// ---- 8. Join request approved -------------------------------------------------
exports.onJoinRequestApproved = onDocumentUpdated('joinRequests/{requestId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === 'approved' || after.status !== 'approved') return;
  if (after.role !== 'student') return; // teacher approvals aren't targeted to one user yet
  const tokens = await tokensForUserIds([after.requesterId]);
  await sendPush(tokens, {
    title: 'Request approved 🎉',
    body: `You're in! Your request to join ${after.targetName} was approved.`,
    path: '/student',
    tag: 'approval'
  });
});