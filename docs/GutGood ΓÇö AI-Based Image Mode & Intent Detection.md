# GutGood — AI-Based Image Mode & Intent Detection

## Objective

Update the GutGood Chat / Meal Analysis / Image Analysis flow so that **AI is the single source of truth for determining what an uploaded image represents and what the user intends to do with it**.

Currently, the same image can produce different results depending on whether the user:
- Takes the photo using the scanner/camera.
- Uploads the same photo from the device gallery.

This must be fixed.

The **same image + same user request must always produce the same analysis mode and equivalent result**, regardless of how the image entered the app.

---

## 1. Remove Manual Image Mode / Intent Detection

Audit the existing codebase and remove/disable manual or hardcoded logic that determines the image mode based on:
- Which button opened the camera.
- Which screen the image came from.
- Gallery vs camera.
- Scanner vs upload.
- Filename or file extension.
- UI route.
- Previously selected mode.
- Manually assigned intent values.
- Separate camera/gallery analysis paths.

Do not let the UI decide what the image is.

For example, do **not** assume:

```text
Camera Scanner → Food
Gallery Upload → Food
Barcode Scanner → Product
Label Scanner → Ingredients
```

The image itself must determine the mode.

---

## 2. Use AI to Classify Every Uploaded Image

Before performing the actual analysis, send the image through a single AI classification step.

The AI should determine what the uploaded image contains.

Supported image modes should include at minimum:

```text
FOOD
RESTAURANT_MENU
PRODUCT_BARCODE
INGREDIENTS_LABEL
NUTRITION_LABEL
PACKAGED_PRODUCT
FOOD_RECIPE
OTHER
UNKNOWN
```

The classifier should inspect the actual visual content.

Examples:

### Food

Image shows:
- A plate of food.
- Cooked meal.
- Fruits/vegetables.
- Beverage.
- Snack.
- Multiple food items.

→ `FOOD`

### Restaurant Menu

Image shows:
- Restaurant menu.
- Food menu board.
- Menu card.
- List of dishes and prices.

→ `RESTAURANT_MENU`

### Product Barcode

Image primarily contains:
- UPC/EAN/GTIN barcode.
- Barcode on packaging.
- Product barcode being scanned.

→ `PRODUCT_BARCODE`

### Ingredients Label

Image shows:
- Ingredient list.
- "Ingredients:"
- Allergen information.
- Food composition text.

→ `INGREDIENTS_LABEL`

### Nutrition Label

Image shows:
- Calories.
- Protein.
- Carbohydrates.
- Fat.
- Serving size.
- Nutrition facts/table.

→ `NUTRITION_LABEL`

### Packaged Product

Image shows:
- Food/product packaging.
- Product front/back.
- Brand/product name.
- Packaging without a clearly dominant barcode or nutrition/ingredient label.

→ `PACKAGED_PRODUCT`

---

## 3. AI Must Also Detect User Intent

Do not maintain a separate manual intent-detection system for image analysis.

The AI should determine both:

```text
IMAGE_MODE
+
USER_INTENT
```

For example:

```text
User: "What is this?"
Image: Food

→ image_mode: FOOD
→ intent: MEAL_RECOGNITION
```

```text
User: "Is this healthy?"
Image: Food

→ image_mode: FOOD
→ intent: HEALTH_ASSESSMENT
```

```text
User: "Rate my lunch"
Image: Food

→ image_mode: FOOD
→ intent: MEAL_RATING
```

```text
User: "What should I swap?"
Image: Food

→ image_mode: FOOD
→ intent: SWAP_REQUEST
```

```text
User: "Tell me everything about this"
Image: Food

→ image_mode: FOOD
→ intent: COMPLETE_ANALYSIS
```

```text
User: "What are the ingredients?"
Image: Packaged product

→ image_mode: INGREDIENTS_LABEL / PACKAGED_PRODUCT
→ intent: INGREDIENT_ANALYSIS
```

```text
User: "Is this product healthy?"
Image: Nutrition label

→ image_mode: NUTRITION_LABEL
→ intent: HEALTH_ASSESSMENT
```

```text
User: "What is this product?"
Image: Barcode

→ image_mode: PRODUCT_BARCODE
→ intent: PRODUCT_IDENTIFICATION
```

---

## 4. Create One Canonical Analysis Pipeline

Camera, gallery upload, scanner and any other image-entry point must converge into the **same analysis pipeline**.

Required architecture:

```text
Camera
   ↓
Gallery
   ↓
Barcode Scanner
   ↓
Other Upload
   ↓
Normalize Image
   ↓
AI Image + Intent Classification
   ↓
Determine Image Mode
   ↓
Determine User Intent
   ↓
Route to Appropriate Analyzer
   ↓
Generate Response
```

There must NOT be separate business logic such as:

```text
cameraAnalysis()
galleryAnalysis()
foodScannerAnalysis()
uploadAnalysis()
```

if those functions independently determine what the image means.

Entry points may remain different at the UI level, but they must eventually use the same canonical analysis service.

---

## 5. AI Classification Result

Create a structured internal result similar to:

```json
{
  "image_mode": "FOOD",
  "intent": "MEAL_RATING",
  "confidence": 0.96,
  "secondary_modes": [],
  "reason": "Image clearly shows a prepared meal and the user asks for a rating."
}
```

For ambiguous images:

```json
{
  "image_mode": "UNKNOWN",
  "intent": "GENERAL_IMAGE_ANALYSIS",
  "confidence": 0.48,
  "secondary_modes": ["PACKAGED_PRODUCT"],
  "reason": "Image does not contain enough visual information to confidently determine the category."
}
```

Use confidence internally for routing and validation.

Do not expose unnecessary internal classification details to the user.

---

## 6. Same Image Must Produce Consistent Results

This is a critical requirement.

If the user uploads the exact same image:

```text
Camera → image
Gallery → same image
```

the application must classify it identically or equivalently.

The source of the image must have **zero influence** on:

- Image mode.
- Intent.
- Analysis type.
- Prompt selection.
- Response structure.
- Nutrition analysis.
- Product analysis.
- Meal analysis.

If image preprocessing is required, normalize images consistently before sending them to AI.

Audit:
- Image resizing.
- Compression.
- MIME type.
- Orientation.
- Cropping.
- EXIF rotation.
- Base64 conversion.
- Multipart upload.
- Image URLs.
- Different Firebase Storage paths.
- Different AI prompts.

Make sure camera and gallery images follow the same preprocessing and AI request format.

---

## 7. User Text Must Be Part of AI Classification

Image classification should not happen independently from the user's message.

The AI should consider:

```text
IMAGE
+
CURRENT USER MESSAGE
+
RELEVANT CONVERSATION CONTEXT
```

For example, the image may be a restaurant menu, but the user says:

> "Which option has the most protein?"

The system should classify:

```text
image_mode: RESTAURANT_MENU
intent: NUTRITION_COMPARISON
```

Another user may upload the exact same menu and say:

> "What should I order?"

Then:

```text
image_mode: RESTAURANT_MENU
intent: FOOD_RECOMMENDATION
```

The image mode remains the same, while the intent changes based on the user's request.

---

## 8. Intent Must Control the Response

Do not always return the same full nutrition report.

Use the detected intent to determine the response format.

Examples:

```text
"Mind my lunch"
→ recognize meal + useful insights

"Rate my lunch"
→ rating + explanation

"Is this healthy?"
→ balanced assessment + why

"What should I swap?"
→ swaps/alternatives only when requested

"Tell me everything"
→ complete detailed analysis
```

The existing GutGood intent-aware response behavior should be preserved and connected to the new AI intent classifier.

Do not regress existing functionality.

---

## 9. Avoid Duplicate Classification Systems

Audit the complete project for:
- Manual intent enums.
- String-based intent checks.
- Route-based intent detection.
- Camera-mode flags.
- Scanner-mode flags.
- Gallery-specific mode detection.
- `if/else` image-type assumptions.
- Separate prompts based only on UI source.
- Hardcoded `"food"` assignments.
- Hardcoded `"label"` assignments.
- Hardcoded `"barcode"` assignments.
- Duplicate AI classification logic.

Consolidate them into one canonical AI classification layer.

The goal is:

```text
ONE IMAGE CLASSIFIER
ONE INTENT CLASSIFIER
ONE ANALYSIS ROUTER
ONE RESPONSE SYSTEM
```

If technically appropriate, image mode and intent can be detected in the same AI call to reduce latency and duplicated processing.

---

## 10. Do Not Break Existing Functionality

This is a refactor/improvement, not a redesign of the entire application.

Preserve:
- Existing UI.
- Existing camera functionality.
- Existing gallery upload.
- Existing scanner functionality.
- Existing Firebase/storage behavior.
- Existing chat history.
- Existing meal logging.
- Existing response rendering.
- Existing nutrition analysis.
- Existing AI capabilities.
- Existing intent-specific response formats.

Only change the logic necessary to make image classification and intent detection AI-driven and consistent.

---

## 11. Handle Ambiguous Images Safely

If AI cannot confidently determine the image type:

Do not guess.

Return:

```text
UNKNOWN
```

or request clarification only when necessary.

Never force an image into `FOOD` simply because it came from the food scanner.

Never force an image into `INGREDIENTS_LABEL` because it was uploaded from a label scanner.

Never force an image into `PRODUCT_BARCODE` because it came from a barcode screen.

**The visual content wins over the UI entry point.**

---

## 12. Testing Requirements

Create test cases for the exact same image.

For each image, test:

```text
Camera capture
Gallery upload
Scanner capture
Re-upload from chat
```

Verify that all produce the same:

```text
image_mode
intent
analysis route
response type
```

Test at minimum:

1. Food photo.
2. Restaurant menu.
3. Barcode.
4. Ingredients label.
5. Nutrition label.
6. Packaged food product.
7. Food + packaging together.
8. Multiple foods.
9. Ambiguous image.
10. Non-food image.

Also test different user questions against the same image:

```text
"What is this?"
"Rate this."
"Is this healthy?"
"What should I swap?"
"Tell me everything."
"What ingredients are in this?"
"How much protein does this have?"
```

The image mode should remain stable while the intent changes appropriately.

---

## 13. Final Acceptance Criteria

The implementation is complete only when:

- AI determines the image mode.
- AI determines the user intent.
- Manual image-mode detection is removed from business logic.
- Manual intent detection is removed from the analysis flow.
- Camera and gallery use the same analysis pipeline.
- Scanner and gallery use the same analysis pipeline where applicable.
- The same image produces consistent classification regardless of upload method.
- User text influences intent detection.
- Image mode and intent are separated conceptually.
- Intent determines the response format.
- Existing GutGood functionality is preserved.
- No duplicate image classification logic remains.
- Ambiguous images are not incorrectly forced into a mode.
- The implementation is centralized, maintainable, and extensible for future image modes.

**Core principle:**

> **Never trust how the image entered the app to determine what the image is. Let AI understand the image and the user's request, then route the request to the correct GutGood analysis.**