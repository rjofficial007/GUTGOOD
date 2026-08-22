# GutGood — Feature Inventory

This inventory identifies all existing features found during the initial codebase audit.

## 🔑 Authentication & Identity
- **Anonymous Sign-in:** Instant access for new users (Guest mode).
- **Permanent Auth:** Email/Magic Link, Google Sign-in, Apple Sign-in.
- **Data Migration:** Atomic merge of guest data (logs, chats) to permanent accounts.
- **Account Management:** Profile settings, goal selection, and secure account deletion.

## 💬 AI Chat Assistant
- **Real-time Streaming:** Token-by-token UI updates via SSE.
- **Persistent History:** Firestore-backed message storage with pagination.
- **Personalized Context:** AI receives user goals, sensitivities, lifestyle, and body rhythm (cycle phase).
- **Summarization:** Rolling chat summarization to maintain long-term context without token blowup.
- **Feedback System:** User thumb-up/down on AI responses.

## 🏷️ Passive & Active Logging
- **Passive Logging (Chat):** AI automatically tags content as `[MEAL]` or `[SYMPTOM]`, which is parsed and logged to Firestore asynchronously.
- **Meal Logs:** Detailed records of food items, photo URLs, and source (chat vs scan).
- **Symptom Logs:** Severity tracking and correlation with timing.
- **Scan History:** Persistent record of all product scans and AI analysis.

## 📷 Hybrid Food Scanner
- **Barcode Lookup:** Open Food Facts integration for deterministic nutrition data.
- **AI Vision Analysis:** Multi-modal analysis of labels, meal photos, and restaurant menus.
- **Fallback Logic:** Automatic transition from failed barcode lookup to Vision-AI analysis.
- **Impact Analysis:** Personalized health score and "Flagged Ingredients" based on user profile.
- **Better Swaps:** AI-recommended healthier alternatives.

## 📊 Insights & Analytics
- **Trigger Detection:** Correlation of meal logs with symptom logs to identify gut irritants.
- **Healing Foods:** Recognition of patterns where specific foods correlate with positive symptoms.
- **Body Rhythm:** Cycle syncing for women to optimize nutrition based on hormonal phases.
- **Trends:** Sparkline visualization of Gut Score over time.

## 💎 GutGood+ (Premium)
- **Entitlement Verification:** RevenueCat integration.
- **Server-Side Quotas:** `aiProxy` enforces daily limits for free users, preventing client-side bypasses.
- **Usage Tracking:** Authoritative daily usage counters stored in Firestore.

## ⚡ Infrastructure & UX
- **Offline Resilience:** Firestore persistence + global `OfflineBanner` indicator.
- **Connectivity Management:** Automatic retry logic for AI requests.
- **App Lifecycle:** State restoration and deep-link handling.
- **Logging:** Centralized `AppLogger` with production redirection to Crashlytics.
