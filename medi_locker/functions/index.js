// Medi Locker — Cloud Functions
// Cura AI backend using Gemini 1.5 Flash
//
// SETUP (one-time):
// 1. cd functions && npm install
// 2. Set your Gemini API key:
//    firebase functions:secrets:set GEMINI_API_KEY
//    (paste your key from https://aistudio.google.com/app/apikey)
// 3. Deploy: firebase deploy --only functions
// 4. Copy the function URL from Firebase Console > Functions
//    and paste it in: lib/features/cura/data/cura_repository.dart

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const admin = require('firebase-admin');

admin.initializeApp();

const geminiApiKey = defineSecret('GEMINI_API_KEY');

// ─── Danger keyword escalation list ─────────────────────────────────────────
const DANGER_KEYWORDS = [
  'chest pain', 'chest tightness', 'heart attack', 'cardiac arrest',
  'difficulty breathing', 'cannot breathe', "can't breathe", 'shortness of breath',
  'severe bleeding', 'uncontrolled bleeding', 'unconscious', 'fainted',
  'stroke', 'sudden numbness', 'sudden paralysis', 'face drooping',
  'suicidal', 'want to die', 'kill myself', 'overdose', 'poisoning',
  'severe allergic reaction', 'anaphylaxis', 'swollen throat',
  'very high fever', 'seizure', 'convulsion',
];

function containsDanger(text) {
  const lower = text.toLowerCase();
  return DANGER_KEYWORDS.some((kw) => lower.includes(kw));
}

// ─── Build Cura system prompt ────────────────────────────────────────────────
function buildSystemPrompt(user, reportContext) {
  const conditions = (user.chronic_conditions || []).join(', ') || 'None';
  const allergies = (user.allergies || []).join(', ') || 'None';
  const bloodGroup = user.blood_group || 'Unknown';

  return `You are Cura, a friendly and empathetic AI health assistant inside the Medi Locker app.

User profile:
- Name: ${user.name || 'User'}
- Blood group: ${bloodGroup}
- Known conditions: ${conditions}
- Allergies: ${allergies}
${reportContext ? `- Latest report context: ${reportContext}` : ''}

Your rules (follow strictly):
1. Be warm, friendly, and easy to understand — avoid complex medical jargon.
2. Give helpful, general health guidance, diet tips, lifestyle suggestions, and home remedies for minor issues.
3. NEVER definitively diagnose any disease.
4. If symptoms sound potentially serious, always say clearly: "Please consult a doctor as soon as possible."
5. If symptoms are an emergency (chest pain, difficulty breathing, etc.) say: "This sounds like a medical emergency. Please call emergency services or go to the nearest hospital immediately."
6. Keep responses concise — under 150 words unless the user asks for detail.
7. If the user asks about medications, give general information only and always recommend consulting a pharmacist or doctor before taking any medicine.
8. Always be honest about the limits of AI health advice.`;
}

// ─── Main Cloud Function ─────────────────────────────────────────────────────
exports.curaChat = onRequest(
  {
    secrets: [geminiApiKey],
    cors: true,
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (req, res) => {
    // Only allow POST
    if (req.method !== 'POST') {
      res.status(405).json({ success: false, error: 'Method not allowed' });
      return;
    }

    try {
      // ── 1. Verify Firebase ID token ──────────────────────────────────
      const authHeader = req.headers.authorization || '';
      const token = authHeader.startsWith('Bearer ')
        ? authHeader.split('Bearer ')[1]
        : null;

      if (!token) {
        res.status(401).json({ success: false, error: 'Unauthorized' });
        return;
      }

      let decoded;
      try {
        decoded = await admin.auth().verifyIdToken(token);
      } catch {
        res.status(401).json({ success: false, error: 'Invalid token' });
        return;
      }

      const { uid, message, reportId } = req.body;

      if (!uid || !message) {
        res.status(400).json({ success: false, error: 'Missing uid or message' });
        return;
      }

      // Verify token matches requested uid
      if (decoded.uid !== uid) {
        res.status(403).json({ success: false, error: 'Forbidden' });
        return;
      }

      // ── 2. Load user profile ─────────────────────────────────────────
      const userDoc = await admin.firestore().collection('users').doc(uid).get();
      const user = userDoc.exists ? userDoc.data() : {};

      // ── 3. Load chat history (last 10 messages for context) ──────────
      const chatsSnap = await admin.firestore()
        .collection('users').doc(uid).collection('chats')
        .orderBy('timestamp', 'desc')
        .limit(10)
        .get();

      const history = chatsSnap.docs
        .reverse()
        .map((d) => d.data())
        .filter((m) => m.message && m.role);

      // ── 4. Load report context if provided ───────────────────────────
      let reportContext = '';
      if (reportId) {
        try {
          const reportDoc = await admin.firestore()
            .collection('users').doc(uid)
            .collection('reports').doc(reportId)
            .get();
          if (reportDoc.exists) {
            reportContext = reportDoc.data()?.ai_summary || '';
          }
        } catch {
          // Report not found — continue without it
        }
      }

      // ── 5. Build prompt ───────────────────────────────────────────────
      const systemPrompt = buildSystemPrompt(user, reportContext);

      const historyText = history.length > 0
        ? history.map((m) =>
            `${m.role === 'user' ? 'User' : 'Cura'}: ${m.message}`
          ).join('\n')
        : '';

      const fullPrompt = historyText
        ? `${systemPrompt}\n\nConversation so far:\n${historyText}\n\nUser: ${message}\nCura:`
        : `${systemPrompt}\n\nUser: ${message}\nCura:`;

      // ── 6. Call Gemini 1.5 Flash ──────────────────────────────────────
      const genAI = new GoogleGenerativeAI(geminiApiKey.value());
      const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

      const result = await model.generateContent(fullPrompt);
      let response = result.response.text().trim();

      // ── 7. Danger keyword check → escalation ─────────────────────────
      const isDanger = containsDanger(message);
      if (isDanger && !response.toLowerCase().includes('emergency')) {
        response += '\n\n⚠️ Important: These symptoms may require immediate medical attention. Please call emergency services or go to your nearest hospital right away.';
      }

      // ── 8. Return response ────────────────────────────────────────────
      res.json({
        success: true,
        response,
        isDanger,
      });

    } catch (error) {
      console.error('curaChat error:', error);
      res.status(500).json({
        success: false,
        error: 'Internal server error',
        response: "I'm having trouble processing your request. Please try again in a moment.",
      });
    }
  }
);
