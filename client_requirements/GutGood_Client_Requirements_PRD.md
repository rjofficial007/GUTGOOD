# GutGood - Client Requirements Document (PRD)
**Version:** 1.0 - Consolidated from all client conversations (First Comment to 11/07/26)
**Date:** 13 July 2026
**Platform:** iOS (MVP)

---

### 1. Executive Summary & Product Vision

**GutGood is an AI food/body assistant that delivers personalized food intelligence, not generic food suggestions.**

Core Philosophy: 
- Food hits different for everybody.
- The app should feel like "I'm just talking... but it's learning me."
- No manual meal logging, calorie tracking, or form-filling. That feels like work.
- Chat = passive logging. Whatever user says/scans automatically becomes a log.
- Speak in **patterns, not absolutes**. Never say food is "good" or "bad" for everyone. Say "Your history shows..." / "You reported..."

**Vision Tagline:** GutGood doesn't nag users — it learns them.

Target tone: Fast, modern, conversational, emotionally personalized, Gen Z / Millennial friendly. Emotional tone, conversational flow, "this app gets me", nuanced wellness language. Not a medical intake form or calorie tracking app.

**Safety Note:** All insights must be framed as patterns, NOT medical diagnosis.

---

### 2. Key Principles (Non-Negotiable)

1.  **Passive Logging Only:** When user says "I ate pizza", "This protein bar messed me up", or scans food -> it AUTOMATICALLY becomes a log. No "Add meal" button. No friction.
2.  **No Manual Work:** Don't make users: Log meals manually, Track calories, Fill forms.
3.  **Personalized Intelligence:** Goal is not generic swaps but personalized based on what user asks, scans, logs, onboarding data.
4.  **Gen Z/Millennial UX:** Lightweight, conversational, emotional.
5.  **Pattern Language:** Never absolute claims. Use "Your energy seems higher..." "Dairy appears often before your bloating logs."

---

### 3. Tech Stack & Architecture - Final Decision

**Evolution:** Initially proposed OpenAI + Open Food Facts + Supabase + Secure Backend. As of 01/07/26, client confirmed to move from Supabase to **Firebase** to handle all data.

**Final MVP Stack:**

**a) OpenAI API - Purpose:**
- AI chat responses
- Image/photo analysis in chat (meal photos, menu photos)
- Ingredient explanations
- Food/body reaction insights
- Swap suggestions
- Cycle sync style insights (cravings, bloating, energy shifts, body rhythm)
- Personalized wellness responses
- Understand what user ate/scanned/typed and convert to structured data
- Explain patterns to user in simple language

**b) Open Food Facts API - Purpose:**
- Barcode scanning
- Product lookup
- Ingredient lists
- Nutrition facts
- Packaged food data

**c) Firebase - Purpose (replaces Supabase):**
- User accounts / authentication
- Chat history
- Saved scans / scan results
- Saved foods / saved meals
- User preferences
- Sensitivities / allergies
- Goals
- Symptoms / check-ins
- Insights / patterns / pattern data
- Gut Score, streak, etc.

**d) App Hosting / Secure Backend/Server - Purpose:**
- Securely connect app to OpenAI
- Protect API keys (never expose OpenAI key on device)
- Handle requests between app, database, and food API
- Run Body Pattern Engine & notification trigger logic

**Core Flow:**
```
User types / uploads photo / scans food (barcode or label)
→ App checks Open Food Facts for product data (if barcode)
→ App sends request to secure backend → OpenAI API (with context: onboarding, goals, sensitivities, lightweight memory)
→ OpenAI returns AI response + structured tags (foods, ingredients, symptoms, timing)
→ Firebase stores structured data
→ Backend logic analyzes patterns → OpenAI explains those patterns
→ Supabase/Firebase saves user patterns so GutGood feels personalized over time
```

**Cost Control Strategy (Important for $4.99 model):**
- Concise AI responses (limit tokens)
- Lightweight memory/context (not full history, only summarized context)
- Limited free usage after trial (3-5 chats/day, 3 scans/day)
- Unlimited premium access at $4.99/month
- Set monthly spending limits inside OpenAI dashboard
- OpenAI billing is pay-per-use (tokens/images) monthly, no large upfront cost

**Why OpenAI (not other LLMs):** Better conversational feel, emotional tone, natural human-feeling conversation for wellness.

---

### 4. User Journey & Auth Flow

**Best Flow Decided (08/06/26):**
1. User opens app
2. Completes onboarding (Guest mode - NO signup before onboarding)
3. Uses chat/scan **1-2 times free** to get value
4. Trigger: App shows: "Create a free account to save your results and start tracking your GutGood Score."
5. Signup Screen: Sign with Apple, Sign with Google, Or Email (keep email simple - as per mockups image9, image10)
6. Start 3-day free trial
7. Enter app - Final screen: "Ready to spill your gut tea?" (Mockup image11)

---

### 5. Onboarding Flow Requirements (8 Steps)

Goal: Fast, modern, conversational, emotionally personalized.

**Step 1: Welcome Screen**
- Headline: "Food hits different for everybody."
- Short intro to GutGood
- Start button

**Step 2: Main Goals (Multi-select)**
Options list must include:
- Better energy
- Less bloating
- Cleaner eating
- Better skin
- Gym performance
- Cravings
- Mood support
- Gut health
- Hormone balance
- Weight balance

**Step 3: Food Sensitivities / Triggers (Multi-select)**
Options:
- Dairy
- Gluten
- Sugar
- Seed oils
- Artificial dyes
- Fast food
- Spicy foods
- "Not sure yet"

**Step 4: Current Lifestyle / Feelings (Multi-select)**
Options:
- Stressed lately
- Low energy
- Bloated often
- Late-night cravings
- Trying to eat cleaner
- Healing my gut
- Gym focused
- Just curious

**Step 5: Optional Body Rhythm / Cycle Sync (for women, optional)**
Copy: "GutGood can personalize insights around cravings, bloating, energy shifts, and body rhythm patterns."
Options:
- Enable
- Skip for now

**Step 6: AI Personalization Screen**
Explain that GutGood learns from:
- scans
- food choices
- cravings
- questions
- habits
to personalize insights over time.

**Step 7: Subscription Screen**
- 3-day unlimited free trial
- Then $4.99/month
- Unlimited scans/chat/personalized insights
- Show paywall UI (image4 reference)

**Step 8: Final Enter App Screen**
- Example copy: "Ready to spill your gut tea?"

UI: Mockups for 3 core screens + onboarding (client provided images 1-4).

---

### 6. Core Screens - Detailed Requirements

#### 6.1 Screen 1: 💬 Chat (Home) - Main Product
**Purpose:** Engagement + Conversion. Paywall triggers here.

**Capabilities:**
- Ask about food
- Ask any medical questions (but answer in pattern/non-diagnosis style)
- Ask food, gut, craving, bloating, ingredient, body reaction questions
- Scan ingredients 📷 (camera icon on chat screen - see image2, image3)
- Upload images / Upload meal photo for AI feedback
- Upload menu photo (for Restaurant Survival Mode)
- Get answers + swaps instantly

**What it does for user:**
- Tell you what's helping or hurting your gut
- Explain why you feel the way you do
- Give you better swaps instantly

**How to use (example prompts to suggest in UI):**
- "Why do I feel bloated after this?"
- "Is this healthy?"
- "What should I eat instead?"

**Passive Logging Rule:** Anything user says about food ("I ate pizza") or scan automatically creates a log for Insights screen without user action.

#### 6.2 Food Scanner (Feature within Chat + Standalone Flow)

**Location:** Scanner icon on chat screen. When you tap scan barcode, show barcode scan screen (image8 reference).

**Capabilities:**
- Barcode scanning via camera
- Label / ingredient photo scanning
- Food/product identification
- Show:
  - Score (Gut Score / Food Score)
  - Flagged ingredients (seed oils, added sugars, preservatives, artificial flavors/dyes, etc.)
  - How it may affect the user (personalized based on goals/sensitivities)
  - Better swaps

**Data Source:** Open Food Facts for packaged data + OpenAI for intelligence layer.

#### 6.3 Screen 2: 📊 Insights (Cause & Effect) - Retention Driver
**Purpose:** Why users stay. Clarity + retention.

**Core Idea:** Shows you how the foods you eat actually impact your body.

Displays:
- What you ate
- How your body responded (bloating, energy, mood, skin, etc.)
- When it happened

**Examples to show:**
- Pizza → bloating (2 hrs later)
- Salmon → better energy (next day)
- Over time: "Dairy is your biggest trigger."

**Components:**
- Gut Score
- Streak
- Food → Effect mapping (bloating, energy, skin)
- Simple trend
- AI insight
- Past insights (saved)

**Image Reference:** image1 (First cause & effect mockup), image12 (shared insight screen insight mockup)

**Data Powered:** What they put in chat should power this screen. Chat + Scans + Behavior → Insight Engine → Impact Screen

**Empty State:** If not enough data, show "No clear pattern yet. Keep logging so GutGood can learn what works for your body."

#### 6.4 Screen 3: 👤 Profile - Identity + Settings

**Purpose:** Control + personalization, Identity + settings.

**Structure (as per image7 mockup and client notes):**

- **📊 Your Gut Snapshot**
  - Your current Gut Score
  - Your streak
  - Quick insight like "Dairy = your trigger"
  - Fast look at how you're doing

- **🎯 Goals**
  - What you want to improve (like energy, skin, digestion)
  - Helps personalize results
  - Multi-select from onboarding list, editable

- **⚠️ Sensitivities**
  - Foods that may affect you (like dairy, gluten, sugar)
  - Keeps insights accurate
  - Editable

- **💳 Membership**
  - Your GutGood+ plan
  - Manage subscription
  - Show free trial status / premium status

- **⚙️ Settings**
  - Notifications (on/off, reminder times, type selection)
  - Privacy
  - Restore purchases

- Additional expected:
  - Saved foods / saved scans history
  - Gut snapshot
  - Allergies (as mentioned in 11/07)
  - Personalization settings

**You can make the screen as you see fit. Client said that's just ideas they played with.**

#### 6.5 Additional Core Feature: Restaurant Survival Mode

**Mentioned in MVP list 11/07/26:**
- User uploads a menu or menu photo
- AI gives healthier recommendations based on goals/sensitivities
- Part of photo food analysis flow

---

### 7. Data Strategy - Where GutGood Gets Data

Client emphasized: Not just tracking "what they ate". Pulling from 4 data streams even without repeats.

**Stream 1: 💬 Chat (Primary Signal)**
Even if they don't log consistently, they say:
- "What should I eat for energy?"
- "Is this snack healthy?"
- "Why do I feel off?"
Tells you their goals, problems, what they're thinking about eating.
Use for: "You've been asking a lot about energy..."

**Stream 2: 📷 Scanner (Strongest Fallback)**
Even randomly:
- ingredients, additives, food type (processed vs whole)
Insights like: "Most foods you've scanned are highly processed..."
No repetition needed.

**Stream 3: 🧠 Ingredient Intelligence (BIG)**
You already know: seed oils, added sugars, preservatives, artificial flavors...
Even ONE scan gives value: "This food contains additives linked to low energy and inflammation."

**Stream 4: 🧍 Onboarding Data (Baseline)**
Goals, sensitivities, symptoms from onboarding.
Use for: "Since your goal is energy, foods high in refined carbs may be working against you."

**System Becomes:** Chat + Scans + Behavior → Insight Engine → Impact Screen

---

### 8. Insight Engine & Body Pattern Engine

#### 8.1 Insight Engine Logic (Simple Logic for MVP)

**If:** repeated foods + symptoms → Pattern Insight (best)
**Else if:** scans ≥ 2-3 → Ingredient Insight
**Else if:** chat questions ≥ 2-3 → Behavioral Insight
**Else:** Goal-based Insight

**Examples (no repetition needed):**
- User scans 2 snacks: "Both foods you scanned contain additives that can impact how your body feels—want cleaner options?"
- User asks random health questions: "You've been focusing on energy—what you eat daily plays a big role in that."
- User barely logs anything: "Based on your goals, focusing on whole foods will help your body perform better."

**Why this works:** Most users won't log perfectly, won't track daily, but they WILL scan, ask questions, explore. That's enough. Requires less data, fewer AI calls, cheaper.

#### 8.2 Insight Generation Rules (Final Rule from 09/06/26)

**Insights = Patterns. Only when enough info.**

**Generate NEW Insight when:**
ANY of these true:
- 3 new scans
- OR 1 meal analysis
- OR 1 symptom log

AND

- At least 24 hours since last insight

**Then:** OpenAI generates insight (example: Coke/Doritos/Takis → Added sugar, Seed oils, Artificial flavors → "I've noticed added sugars and processed ingredients appearing frequently in your recent choices. Small swaps could support steadier energy.")
Save it to Firebase.

**If not meeting condition:** Show previously saved insight (do not generate new).

**Example table:**
| Trigger | Example Logic | Output |
|---|---|---|
| Scans: Coke, Doritos, Takis | Detects added sugar, seed oils, artificial flavors | Ingredient frequency insight |

#### 8.3 Body Pattern Engine (Backend Feature)

**Goal:** Helps GutGood learn from each user over time.

**Comparisons backend should do:**
- foods eaten vs bloating
- protein before noon vs energy
- dairy/gluten vs symptoms
- sugar vs crashes
- caffeine timing vs sleep
- fiber vs stool/digestion

**Pattern examples to surface:**
- "Your energy seems higher on days you eat protein earlier."
- "Dairy appears often before your bloating logs."

**Framed as patterns, not medical diagnosis.**

**Flow with Firebase:**
OpenAI understands food/chat → Firebase stores structured data (meal logs, food tags, ingredients, scan source, meal timing, symptoms, energy, mood, sleep) → Backend logic analyzes patterns → OpenAI explains those patterns to user in simple language.

**Structured Data to Save (for notifications):**
- meal logs, food tags, ingredients, scan source, meal timing, symptoms, energy, mood, sleep, other check-ins

---

### 9. Smart Notifications

#### 9.1 Vision: Differentiator

Do NOT want generic reminders like "Log your meal" or "Drink water." Want every notification to be **earned by user's own data.**

**Examples of Smart Pattern-Based Notifications:**
- "You've reported feeling more energized after eating breakfast before 9 AM."
- "The last 3 times you ate late, you reported lower energy the next morning."
- "Meals containing onions have been followed by bloating 4 out of your last 5 times."
- "No clear pattern yet. Keep logging so GutGood can learn what works for your body."

**Four Core Pieces to Build:**
1. Structured data system that saves meal logs, food tags, ingredients, scan source, meal timing, symptoms, energy, mood, sleep
2. Pattern engine that detects repeated user-specific patterns
3. Confidence rules so GutGood does not show insights too early (only after enough meals, check-ins, repeat behavior)
4. Notification trigger system that sends insights at right time (after check-in, weekly report, when user scans/logs food connected to past symptoms)

**Main Principle:** GutGood should not make absolute claims. Say "Your history shows..." or "You reported..." based on user's own data.

#### 9.2 MVP V1 Basic Smart Notifications (From 11/07/26)

For Version 1, keep notifications simple and triggered by simple rules - short, actionable, personal (like Apple notifications). Even this V1 should be personal.

**Notification Copy List (Use these exacts):**

🍽️ Lunch Reminder - Title: GutGood - Body: "How are you feeling after lunch? Take 30 seconds to log your meal."

📸 Meal Reminder - Title: GutGood - Body: "Snap your next meal. We'll help you understand what's on your plate."

📝 Daily Check-in - Title: GutGood - Body: "Don't forget today's check-in. Every meal helps build your personal insights."

🌙 Evening Check-in - Title: GutGood - Body: "How did dinner make you feel? Log symptoms, energy, or mood."

📷 Food Scan Reminder - Title: GutGood - Body: "Eating something new? Scan it before you take your first bite."

⏰ Missed Logging - Title: GutGood - Body: "No meals logged today. Take one minute to check in."

🍽️ Restaurant Reminder - Title: GutGood - Body: "Eating out tonight? Upload the menu before you order."

Additional Basic Versions Mentioned:
- "You haven't logged a meal today."
- "How are you feeling after lunch?"
- "Remember to rate how this meal made you feel."
- "You scanned 3 processed foods this week. Want healthier swaps?"

**V1 Trigger Rules:**
1. **Meal Reminder:** Around user's selected breakfast, lunch, or dinner time (if they enabled reminders)
2. **Post-meal Check-in:** 1-2 hours after a meal is logged. Example: "How are you feeling after your last meal?"
3. **No Meal Logged:** If no meal logged by evening (e.g., 7 PM), send "You haven't logged a meal today. Take 30 seconds to check in."
4. **Daily Reminder:** One reminder per day at user's preferred time if they haven't opened the app.

**User Controls:**
- Turn notifications on/off
- Choose reminder times
- Choose which notifications they want to receive

---

### 10. Subscription & Monetization (iOS Only)

**Model:** 3-day free trial before $4.99/month subscription starts.

**Free Trial (3 days unlimited):**
Allow users to:
- chat with AI
- upload food photos
- scan products
- receive ingredient/body insights
- experience core GutGood flow before subscribing

**Premium Plan - $4.99/month - Unlocks full experience:**
- unlimited AI chat
- unlimited food/photo scans
- ingredient breakdowns
- personalized food & body insights
- smarter food swaps
- saved food history/patterns
- cycle sync insights
- weekly gut recap insights
- deeper personalized answers over time as GutGood learns user

**Free Version (after trial or if user doesn't subscribe, freemium):**
- 3-5 AI chats daily
- 3 food/photo scans daily
- basic ingredient insights
- basic food swaps
- limited personalized wellness insights
- Can still experience core GutGood app before upgrading

**Paywall Logic:**
- Once users hit daily limit (3-5 chats or 3 scans), show premium subscription screen
- Paywall triggers in Chat (Home) screen as well
- Paywall UI from image4 reference - 3 day free trial

**Store Items:** Manage subscription, Restore purchases in Profile.

---

### 11. MVP Scope - Final Checklist (From 11/07 + All Comments)

Based on everything we’ve planned, MVP includes:

1.  **AI Chat** – Users can ask nutrition and gut health questions. Personalized wellness responses.
2.  **Photo Food Analysis** – Upload a meal photo for AI feedback (score, ingredients, body impact)
3.  **Barcode/Product Scan** – Scan packaged foods for ingredient insights (Open Food Facts + OpenAI)
4.  **Restaurant Survival Mode** – Upload a menu or menu photo for healthier recommendations
5.  **Food Impact (Cause & Effect)** – Save meals and how they made you feel, show patterns, Gut Score, streak, AI insight
6.  **Profile** – User preferences, allergies, goals, sensitivities, saved foods, gut snapshot, subscription, settings
7.  **Premium Paywall** – Free trial with subscription access ($4.99/month), limited free daily usage
8.  **Basic Smart Notifications** – Meal reminders, post-meal check-ins, daily reminders, missed logging, scan reminders
9.  **Body Pattern Engine (Backend)** – OpenAI → Firebase structured data → pattern analysis → OpenAI explanation
10. **Onboarding** – 8-step flow, Guest first, then signup
11. **Passive Logging System** – Chat = log automatically

**Not in MVP (Future):**
- Advanced/expensive systems beyond OpenAI/Open Food Facts/Firebase
- Full Smart Notifications powered by personal patterns (confidence rules + trigger system) - this is V2 vision but architecture should support it
- More advanced cycle sync? Basic included in premium.

---

### 12. Personalization & Tone Rules

- Emotional, human-feeling conversation
- Gen Z / millennial friendly copy: "Ready to spill your gut tea?"
- Concise AI responses (cost + UX)
- No medical diagnosis claims - only patterns
- Personalized based on: goals, sensitivities, lifestyle, chat behavior, scans, onboarding, ingredient intelligence
- Deeper personalization over time as app learns

---

### 13. Analytics / Data Storage Schema Hints

Firebase collections suggested:

- `users`: uid, email, authProvider (Apple/Google/email), goals[], sensitivities[], lifestyle[], cycleSyncEnabled bool, createdAt, subscriptionStatus, gutScore, streak
- `chatHistory`: userId, messages[], timestamp, structuredFoodMentions[], structuredSymptoms[]
- `scanHistory`: userId, barcode, productName, ingredients[], flaggedIngredients[], score, source (barcode/photo), timestamp
- `mealLogs`: userId, foodTags[], mealType, mealTime, photoUrl, analysisResult
- `symptomCheckIns`: userId, symptom (bloating, energy, mood, skin, craving, sleep, stool), energyLevel, mood, sleep, timestamp, relatedMealId
- `insights`: userId, insightText, type (Pattern/Ingredient/Behavioral/Goal), confidenceLevel, generatedAt, triggerData (3 scans / 1 meal / 1 symptom)
- `patternData`: aggregated comparisons
- `notifications`: preferences, reminderTimes, enabledTypes[]

---

### 14. Acceptance Criteria - Important Edge Cases

- Onboarding must allow multi-select
- User can select "Not sure yet" for sensitivities and skip cycle sync
- Guest can use 1-2 chats/scans without account, then forced to create account to save results
- Insight should not generate if <24h since last AND < triggers met
- Previously saved insight should be shown otherwise
- Scanner must handle no product found in Open Food Facts -> fallback to OpenAI vision analysis
- Free user hitting limit -> paywall blocks further chat/scan but allows viewing past insights/snapshot?
- Notifications must respect on/off toggle
- All pattern statements must include "You reported" / "Your history shows" / "appears often" language
- App must work with ingredient intelligence even with 1 scan only

---

### 15. Open Questions / Assets Needed

- Final UI mockups for all images (image1 to image12 were base64 in original - need export as separate assets)
- Exact Gut Score calculation logic
- Branding, colors
- Legal disclaimer for non-medical advice
- iOS StoreKit in-app purchase setup for $4.99/month

---

### 16. Summary of All Screens to Design/Build

- Welcome
- Main Goals
- Sensitivities
- Current Lifestyle
- Body Rhythm / Cycle Sync Optional
- AI Personalization Explainer
- Subscription / Paywall (3-day free trial)
- Enter App (Spill your gut tea)
- Chat (Home) + Scanner icon + Photo upload + Menu upload
- Barcode Scanner Result Screen (Score, flagged, impact, swaps)
- Meal Photo Analysis Result Screen
- Insights / Cause & Effect Screen (Gut Score, streak, Food → Effect list, Trends, AI Insight)
- Profile / Gut Snapshot / Goals / Sensitivities / Membership / Settings / Notifications Settings
- Auth Screen (Apple, Google, Email simple)
- Daily Check-in / Symptom Log (bloat, energy, mood, sleep)

---

**This document captures every point from the raw client conversation without omission. Use this as source of truth for MVP build.**
