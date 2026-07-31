# API Reference

GutGood communicates with external services primarily through secure Firebase Cloud Functions and RESTful third-party APIs.

## 1. GutGood AI Proxy (Cloud Function)
**Endpoint:** `POST https://{region}-{project}.cloudfunctions.net/aiProxy`
**Security:** Requires `Authorization: Bearer <Firebase_ID_Token>`.

### Request Body
| Field | Type | Description |
| --- | --- | --- |
| `mode` | String | `stream` (default), `json`, or `plain`. |
| `usageType` | String | `chat`, `scan`, or `system`. Used for quota tracking. |
| `userText` | String | Current user prompt. |
| `systemInstruction`| String | AI system behavior instructions. |
| `messages` | List | Conversation history (role/content). |
| `images` | List<String> | Base64 encoded JPEG images (max 4). |
| `idempotencyKey` | String | Optional key to prevent double-charging quotas. |

### Response
- **Stream Mode:** `text/event-stream`. Data frames: `data: {"d": "token"}`.
- **JSON/Plain Mode:** Standard JSON `{"text": "..."}`.
- **Errors:** JSON `{"error": "error_code", "message": "..."}`. Common codes: `quota_exceeded`, `unauthenticated`, `upstream_error`.

---

## 2. Account Merge (Cloud Function)
**Endpoint:** `Callable mergeAnonymousAccount`
**Responsibility:** Moves all user-associated collections from an anonymous UID to a permanent UID.

### Request
```json
{ "anonymousUid": "TEMP_UID_123" }
```

### Response
```json
{ "success": true, "alreadyMerged": false }
```

---

## 3. Open Food Facts API (External)
**Base URL:** `https://world.openfoodfacts.org/api/v2/`
**Used by:** `OffService`.

### Product Lookup
- **Endpoint:** `GET /product/{barcode}.json`
- **Fields Requested:** `product_name`, `brands`, `ingredients_text`, `nutriments`, `nutriscore_grade`, `nova_group`, `categories_tags`.

### Product Search (Swaps)
- **Endpoint:** `GET /search.json`
- **Filter:** `categories_tags_en`, `nutriscore_grade < current_product`.

---

## 4. RevenueCat (External)
**Base URL:** `https://api.revenuecat.com/v1/`
**Used by:** `PurchaseService` (via SDK).
**Functionality:** Validates app store receipts and provides entitlement status.

---

## 5. Firebase Admin SDK (Internal)
Used within Cloud Functions for:
- Verifying ID tokens.
- Transactional increments of `daily_usage` counters.
- Bulk deletion of data in `onUserDeleted` triggers.
