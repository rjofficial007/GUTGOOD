# Firestore Database Schema

The GutGood database is structured around a single root collection, `user_profiles`, with all user-specific data organized into subcollections under each user's UID.

## 1. `user_profiles` (Root Collection)
**Purpose:** Stores core user identity, health profile, and personalization settings.

| Field | Type | Description |
| --- | --- | --- |
| `uid` | String | Firebase Authentication UID. |
| `displayName` | String | User's preferred name or "Guest". |
| `email` | String | Authenticated email address. |
| `photoUrl` | String | URL to profile picture in Storage. |
| `onboarded` | Boolean | Whether onboarding is complete. |
| `isPremium` | Boolean | Whether user has active subscription. |
| `subscriptionStatus` | String | "free" or "premium". |
| `isAnonymous` | Boolean | Whether the account is guest/anonymous. |
| `authProvider` | String | Login method (google.com, apple.com, etc). |
| `goals` | List<String> | Selected health goals. |
| `sensitivities` | List<String> | Selected food sensitivities. |
| `lifestyle` | List<String> | Selected lifestyle factors. |
| `cycleSyncEnabled` | Boolean | Opt-in status for hormonal tracking. |
| `cyclePhase` | String | Current menstrual cycle phase. |
| `chatSummary` | String | AI-generated rolling summary of recent history. |
| `gutScore` | Number | Aggregated health score (0-100). |
| `streak` | Number | Current daily check-in streak. |
| `longestStreak`| Number | All-time highest streak achieved. |
| `lastActivityDate`| String | ISO Date (YYYY-MM-DD) of last active session. |
| `timezoneOffset`| Number | User's local timezone offset in minutes. |
| `notificationPreferences` | Map | User's alert settings. |
| `createdAt` | Timestamp | Account creation time. |
| `updatedAt` | Timestamp | Last profile update time. |

---

## 2. `user_profiles/{uid}/chat_history` (Subcollection)
**Purpose:** Stores conversational turns between the user and AI.

| Field | Type | Description |
| --- | --- | --- |
| `localId` | String | Client-side UUID for deduplication. |
| `role` | String | "user" or "ai". |
| `text` | String | Message content (Markdown). |
| `imageUrls` | List<String> | Storage URLs for attached images. |
| `scanData` | Map | Embedded `ScanResult` if AI analyzed a product. |
| `swapData` | List<Map> | AI-suggested product alternatives. |
| `isSwap` | Boolean | Flag for swap-heavy responses. |
| `feedback` | String | "helpful" or "not_helpful". |
| `foodMentions` | List<String> | Automatically extracted food items. |
| `symptomMentions` | List<String> | Automatically extracted symptoms. |
| `time` | Timestamp | Message creation time. |

---

## 3. `user_profiles/{uid}/scan_history` (Subcollection)
**Purpose:** Stores detailed results of food scans (Barcode/Vision).

| Field | Type | Description |
| --- | --- | --- |
| `productName` | String | Name of the scanned item. |
| `brand` | String | Product manufacturer. |
| `score` | Number | Gut health score (0-100). |
| `impactType` | String | "positive", "neutral", or "negative". |
| `impact` | String | Summary of health effects. |
| `nutriscore` | String | Grade (A-E). |
| `novaGroup` | String | Processing level (1-4). |
| `barcode` | String | EAN/UPC barcode string. |
| `userImageUrl` | String | Storage URL of the photo taken. |
| `flaggedIngredients` | List<String> | Ingredients triggering sensitivities. |
| `time` | Timestamp | Scan creation time. |

---

## 4. `user_profiles/{uid}/meal_logs` (Subcollection)
**Purpose:** Tracks consumed food items.

| Field | Type | Description |
| --- | --- | --- |
| `items` | List<String> | Description of items eaten. |
| `mealType` | String | "breakfast", "lunch", "dinner", "snack". |
| `photoUrl` | String | Storage URL of the meal photo. |
| `source` | String | "chat", "scanner", or "manual". |
| `foodTags` | List<String> | AI-extracted health tags. |
| `time` | Timestamp | Consumption time. |

---

## 5. `user_profiles/{uid}/symptom_logs` (Subcollection)
**Purpose:** Tracks physical reactions and energy levels.

| Field | Type | Description |
| --- | --- | --- |
| `symptom` | String | Reported symptom (e.g., Bloating). |
| `severity` | Number | Scale (1-10). |
| `energyLevel` | Number | Scale (1-10). |
| `notes` | String | Free-form details. |
| `source` | String | "chat" or "manual". |
| `time` | Timestamp | Symptom occurrence time. |

---

## 6. `user_profiles/{uid}/insights` (Subcollection)
**Purpose:** AI-generated recaps and pattern analysis.

| Field | Type | Description |
| --- | --- | --- |
| `title` | String | Recap title (e.g. "Weekly Summary"). |
| `summary` | String | Narrative overview. |
| `patterns` | List<Map> | Identified food-symptom correlations. |
| `updatedAt` | Timestamp | Insight generation time. |

---

## 7. `user_profiles/{uid}/daily_usage` (Subcollection)
**Purpose:** Server-managed rate limits (Counter collection).

| Field | Type | Description |
| --- | --- | --- |
| `messages` | Number | Total AI messages sent today. |
| `scans` | Number | Total food scans performed today. |
| `date` | String | ISO Date (YYYY-MM-DD). |

> [!IMPORTANT]
> This collection is **read-only** for clients. Increments are performed server-side by the `aiProxy` Cloud Function to prevent tampering.
