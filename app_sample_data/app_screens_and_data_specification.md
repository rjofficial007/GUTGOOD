# GutGood App Screens & Core Data Specifications

This document outlines the data schemas, related screens, and comprehensive mock data for the remaining core features of the GutGood app:
1. **Scanner & Scan Results (`ScanResult`)**
2. **Journal & Timeline (`MealLog`, `SymptomLog`)**
3. **Chat & AI Messaging (`ChatMessage`)**
4. **User Profile (`UserProfile`)**

---

## 1. Scanner & Scan Results (`ScanResult`)

### Related Screens
- **Scan Result Screen (`ScanResultScreen`)**: Displays food identity header, score gauge (`ScanScoreHeader`), quick metrics, positives/negatives, better swaps, additives, and ingredients.
- **Saved Foods Screen**: Grid of saved/bookmarked food scans.
- **All Scans History**: Chronological list of past product, label, and menu scans.

### Mock Data JSON (`ScanResult`)
```json
{
  "v": 1,
  "scanId": "scan_yogurt_001",
  "productName": "Organic Greek Yogurt & Berries",
  "brand": "GutGood Organics",
  "category": "meal",
  "score": 92,
  "impactType": "positive",
  "impact": "An exceptional, high-protein probiotic choice that promotes microbiome diversity.",
  "summary": "Creamy organic Greek yogurt topped with fresh antioxidant-rich blueberries.",
  "badge": "Gut Builder",
  "nutriscore": "A",
  "novaGroup": 1,
  "nutriscoreScore": 95,
  "isOrganic": true,
  "allergens": "Milk",
  "additives": "None",
  "additiveItems": [],
  "ingredients": [
    { "name": "Organic Cultured Pasteurized Nonfat Milk", "percentage": "80%" },
    { "name": "Organic Blueberries", "percentage": "20%" }
  ],
  "nutrients": {
    "calories": 150,
    "protein": 18.0,
    "carbs": 12.0,
    "sugars": 8.0,
    "fat": 2.0,
    "saturatedFat": 0.5,
    "fiber": 3.0,
    "salt": 0.1
  },
  "nutrientLevels": {
    "sugars": "low",
    "fat": "low",
    "saturatedFat": "low",
    "salt": "low"
  },
  "impacts": [
    { "title": "Probiotic Rich", "description": "Live active cultures support gut flora.", "isPositive": true },
    { "title": "High Protein", "description": "Sustains energy without blood sugar spikes.", "isPositive": true }
  ],
  "swaps": [],
  "barcode": "0782345678901",
  "source": "camera",
  "userImageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777",
  "isSaved": true,
  "nutritionEstimated": true,
  "createdAt": "2024-09-14T08:30:00.000Z"
}
```

---

## 2. Journal & Timeline (`MealLog` & `SymptomLog`)

### Related Screens
- **History Hub / Journal Timeline (`ScanHistoryScreen`)**: Chronological day-grouped list of meals, scans, and symptoms.
- **Symptom Logging & Detail Screen**: Tracks digestion symptoms, severity, onset time, and related food triggers.

### Mock Data JSON (`MealLog`)
```json
{
  "id": 101,
  "firestoreId": "meal_101",
  "items": ["Avocado Toast", "Poached Egg", "Kombucha"],
  "score": 85,
  "summary": "Nourishing breakfast with healthy fats and live probiotics.",
  "photoUrl": "https://images.unsplash.com/photo-1525351484163-7529414344d8",
  "foodTags": ["avocado", "egg", "kombucha"],
  "eventTime": "2024-09-14T09:00:00.000Z",
  "createdAt": "2024-09-14T09:05:00.000Z",
  "source": "chat"
}
```

### Mock Data JSON (`SymptomLog`)
```json
{
  "id": 201,
  "firestoreId": "symptom_201",
  "symptom": "Mild bloating",
  "severity": 2,
  "timeAfter": "2 hours after lunch",
  "foodName": "Deep-Fried Onion Rings",
  "notes": "Felt heavy after eating fried sides.",
  "imageUrl": null,
  "eventTime": "2024-09-14T14:00:00.000Z",
  "createdAt": "2024-09-14T14:10:00.000Z",
  "source": "chat"
}
```

---

## 3. Chat & AI Messaging (`ChatMessage`)

### Related Screens
- **Chat Screen (`ChatScreen`)**: Conversational AI assistant for scanning foods, logging symptoms, asking gut health questions, and receiving instant actionable guidance.

### Mock Data JSON (`ChatMessage`)
```json
{
  "localId": "msg_001",
  "role": "ai",
  "text": "I analyzed **Organic Greek Yogurt & Berries** for you. ✨\n\n**GutGood Rating: 92/100 — Thriving**",
  "imageUrls": ["https://images.unsplash.com/photo-1488477181946-6428a0291777"],
  "isSwap": false,
  "foodMentions": ["Greek Yogurt", "Blueberries"],
  "symptomMentions": [],
  "createdAt": "2024-09-14T08:31:00.000Z"
}
```

---

## 4. User Profile (`UserProfile`)

### Related Screens
- **Profile & Settings Screen (`ProfileScreen`)**: Displays user goals, sensitivities, cycle synchronization settings, and subscription/premium status.

### Mock Data JSON (`UserProfile`)
```json
{
  "uid": "user_test_123",
  "email": "user@gutgood.app",
  "displayName": "Alex Morgan",
  "goals": ["Improve gut health", "Reduce bloating", "Increase energy"],
  "sensitivities": ["Dairy (mild)", "Gluten"],
  "lifestyle": ["Active", "Balanced diet"],
  "cycleSyncEnabled": true,
  "cyclePhase": "Luteal Phase",
  "isPremium": true,
  "onboarded": true,
  "createdAt": "2024-08-01T00:00:00.000Z",
  "updatedAt": "2024-09-14T00:00:00.000Z"
}
```
