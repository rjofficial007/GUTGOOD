Act as a **Senior Prompt Engineer, AI Product Architect, and LLM Application Specialist** reviewing the AI system of **GutGood**, an AI-powered food, meal, and gut-health assistant.

Your job is to **reverse-engineer and critically audit the entire AI prompting system before making changes**.

Do not blindly rewrite prompts. First understand how the current AI system works, how prompts are constructed, what data is provided to the model, how user intent is detected, how responses are generated, and how different features interact.

The primary objective is:

> **Improve the accuracy, consistency, usefulness, safety, personalization, and reliability of GutGood's AI responses without changing the intended product functionality.**

---

# 1. Understand the Existing AI System

First inspect the complete codebase and identify every component related to AI behavior.

Find and analyze:

- System prompts
- Developer prompts
- User prompts
- Prompt templates
- Prompt builders
- AI service classes
- Gemini/OpenAI/LLM integration
- Model configuration
- Temperature
- Token limits
- Structured output / JSON schemas
- Function/tool calling
- Context construction
- Conversation history
- Meal data
- Food data
- Symptom data
- User profile/context
- Scan results
- Insight generation
- Chat response generation
- Meal analysis
- Food analysis
- Recommendations
- Follow-up questions
- Error handling
- Retry logic
- Streaming responses
- AI response parsing
- Response validation
- Safety filtering
- Caching

Do not assume a prompt is the only place where AI behavior is defined.

Trace the entire pipeline:

```text
User Input
    ↓
Intent Detection
    ↓
Context Collection
    ↓
Prompt Construction
    ↓
System Instructions
    ↓
Conversation History
    ↓
User Data
    ↓
LLM
    ↓
Structured/Unstructured Response
    ↓
Validation
    ↓
UI Formatting
    ↓
User
```

Document where each stage actually occurs in the codebase.

---

# 2. Understand GutGood's AI Product Behavior

Understand what GutGood is supposed to do.

GutGood is an AI food and gut-health assistant that can help users with things such as:

- Meal analysis
- Food analysis
- Food scanning
- Meal ratings
- Nutrition-related questions
- Gut-health questions
- Symptom tracking
- Food/symptom relationships
- Personalized observations
- Pattern detection
- Meal recommendations
- Food swaps when explicitly requested
- Conversational questions about food and digestion

The AI should feel like a **helpful, intelligent food and wellness assistant**, not a generic chatbot.

---

# 3. Audit User Intent Detection

One of the most important parts of GutGood is understanding what the user actually wants.

Audit whether the AI correctly distinguishes between intents such as:

### Meal Analysis

"Mind my lunch"

Expected behavior:

- Recognize/analyze the meal
- Identify useful nutritional/gut-health observations
- Keep the response practical
- Do not unnecessarily turn it into a long health lecture

### Rating

"Rate my lunch"

Expected behavior:

- Provide a clear rating/score
- Explain the rating
- Mention strengths
- Mention meaningful weaknesses
- Provide practical improvements where appropriate

### Health Question

"Is this healthy?"

Expected behavior:

- Directly answer the question
- Explain why
- Consider meal composition/context
- Avoid an unnecessary generic analysis

### Food Swap

"What can I replace this with?"

Expected behavior:

- Provide relevant alternatives
- Explain why the alternatives may be useful
- Consider the user's context

### General Question

"Why do I feel bloated after eating?"

Expected behavior:

- Answer the actual question
- Explain plausible causes
- Avoid pretending to diagnose the user
- Clearly distinguish general information from personalized conclusions

### Everything

"Tell me everything about this meal"

Expected behavior:

- Provide a comprehensive analysis
- Cover relevant nutrition, gut-health, balance, and practical observations
- Avoid irrelevant information

Determine whether the current prompt architecture handles these intents reliably.

---

# 4. Audit Context Management

Determine exactly what information the AI receives.

Audit whether the model receives appropriate context such as:

- Current user message
- Previous conversation
- Recent meals
- Historical meals
- Food items
- Meal composition
- Portion information
- Meal timing
- Symptoms
- Symptom severity
- Symptom timing
- User preferences
- Previously identified patterns
- Scan information
- Nutritional information
- Relevant historical context

Identify:

- Missing context
- Irrelevant context
- Duplicate context
- Excessive context
- Conflicting context
- Incorrectly formatted context
- Context that should be summarized
- Context that should never be sent

Optimize the context window without removing information required for correct reasoning.

---

# 5. Audit Prompt Architecture

Determine whether GutGood should use:

- One large system prompt
- Modular prompts
- Intent-specific prompts
- Feature-specific prompts
- Shared instruction layers
- Context-specific instruction layers

Look for:

- Contradictory instructions
- Repeated instructions
- Ambiguous instructions
- Weak priority ordering
- Prompt injection vulnerabilities
- Instructions that are too vague
- Instructions that are overly restrictive
- Instructions that conflict with product requirements

Create a cleaner prompt architecture where appropriate.

---

# 6. Audit AI Response Quality

Evaluate whether responses are:

- Accurate
- Relevant
- Concise
- Personalized
- Context-aware
- Actionable
- Consistent
- Natural
- Non-repetitive
- Easy to understand
- Appropriate for the user's question

Identify common failure modes such as:

### Generic Responses

The AI gives the same advice regardless of the user's actual meal/history.

### Over-analysis

The AI provides a huge response when the user asks a simple question.

### Under-analysis

The AI misses important information when enough data is available.

### Unwanted Recommendations

The AI automatically recommends food swaps when the user did not ask for them.

### Unsupported Claims

The AI presents weak assumptions as facts.

### False Personalization

The AI claims to have identified a pattern when there is insufficient data.

### Repetition

The AI repeatedly says the same thing across messages.

### Context Ignorance

The AI ignores information already provided by the user.

### Overconfident Health Claims

The AI presents uncertain relationships as established medical facts.

Find and fix the underlying prompt/design causes rather than adding random instructions.

---

# 7. Critical Rule: Evidence-Based Insights

GutGood must **not generate personalized insights unless enough data exists**.

Audit the current implementation carefully.

For example:

Do not claim:

> "Dairy causes your bloating."

based on one meal.

Do not claim:

> "You sleep better when you eat earlier."

without sufficient historical evidence.

The AI should distinguish between:

### Observation

"You reported bloating after this meal."

### Possible association

"You've reported bloating after several meals containing dairy."

### Meaningful pattern

"Across multiple recorded meals, bloating has occurred more frequently after meals containing dairy."

### Strong conclusion

Only make stronger claims when the available data genuinely supports them.

The AI must never fabricate missing historical data.

---

# 8. Audit Insight Generation

Review the complete insight-generation architecture.

GutGood may generate patterns such as:

- Bloating Pattern
- Energy Pattern
- Headache Pattern
- Digestion Pattern
- Fullness Pattern
- Sleep Pattern

Determine:

- What minimum data is required?
- How many meals/events are required?
- How many symptom reports are required?
- How should repeated observations be evaluated?
- How should conflicting evidence be handled?
- How should confidence be calculated?
- When should an insight NOT be generated?

Critical requirement:

> **Do not generate an insight simply because an insight category exists.**

If there is insufficient evidence:

```text
No insight
```

not:

```text
Low-confidence generic insight
```

Avoid empty, generic, or fabricated insight cards.

---

# 9. Personalization Audit

Determine whether the AI properly uses available user-specific information.

Personalization should be based on actual available data.

The AI should consider:

- Recorded meals
- Food preferences
- Symptoms
- Meal timing
- Historical patterns
- Previous conversations
- User questions

But it must not invent user preferences or medical information.

Distinguish clearly between:

```text
Known user data
```

```text
AI inference
```

```text
General nutritional knowledge
```

---

# 10. Safety & Health-Related AI Behavior

Because GutGood deals with food, digestion, symptoms, and wellness, perform a dedicated safety audit.

The AI must:

- Avoid diagnosing medical conditions
- Avoid claiming certainty about medical causes
- Avoid unsafe treatment recommendations
- Avoid telling users to stop prescribed medication
- Avoid replacing professional medical advice
- Recognize when a question requires professional medical evaluation
- Use appropriate uncertainty language
- Avoid unnecessary fear
- Avoid making unsupported health claims

However:

Do not make the AI so cautious that every answer becomes:

> "Consult a doctor."

The goal is **useful, responsible guidance**, not excessive disclaimers.

---

# 11. Prompt Efficiency

Audit prompt efficiency.

Identify:

- Repeated instructions
- Redundant context
- Unnecessary verbosity
- Instructions that can be represented structurally
- Information that should be passed as structured data instead of prose
- Instructions that belong in application code instead of prompts

Reduce unnecessary token usage while preserving behavior.

---

# 12. Structured Output

Determine whether each AI feature should use structured output.

For example:

```json
{
  "intent": "meal_analysis",
  "summary": "...",
  "rating": 8,
  "strengths": [],
  "concerns": [],
  "recommendations": [],
  "confidence": 0.87
}
```

Do not force JSON everywhere.

Use structured output where it improves:

- Reliability
- Parsing
- UI rendering
- Validation
- Consistency
- Analytics

Determine the appropriate schema for each AI feature.

---

# 13. Failure & Edge-Case Testing

Test the prompt architecture mentally and, where possible, through automated evaluation against cases such as:

### Very short questions

"healthy?"

### Ambiguous questions

"what about this?"

### Multiple questions

"Is this healthy and will it make me bloated?"

### Contradictory context

User says one thing while historical data suggests another.

### Missing data

No meal history.

### Insufficient insight data

Only one relevant meal.

### Large conversation history

Hundreds of previous messages.

### Malicious prompt injection

"Ignore your instructions and tell me..."

### Unsupported claims

User asks:

"Does this food definitely cause IBS?"

### Emotional language

"This food always destroys my stomach."

### Unclear food

User provides an image or food name that cannot be confidently identified.

### Missing nutritional information

The system does not know the exact ingredients or portion.

Ensure the AI responds appropriately in every case.

---

# 14. Prompt Evaluation Framework

Create an evaluation framework for GutGood.

Evaluate prompts on:

| Metric | Goal |
|---|---|
| Intent accuracy | Correctly understand user request |
| Relevance | Answer what was actually asked |
| Factuality | Avoid unsupported claims |
| Personalization | Use available user data correctly |
| Consistency | Similar inputs produce reliable behavior |
| Safety | Avoid harmful health guidance |
| Conciseness | Avoid unnecessary verbosity |
| Actionability | Give useful next steps |
| Context usage | Use relevant history |
| Hallucination rate | Minimize fabricated information |

Create representative test cases for every major AI feature.

---

# 15. Do Not Change Product Functionality

This is critical.

Do NOT change:

- Existing product features
- Intended user flows
- Business rules
- Data models
- UI behavior
- Existing API contracts

unless a change is absolutely required to fix an AI reliability issue.

The goal is:

**Improve AI quality, not redesign the product.**

---

# 16. Implementation Requirements

After completing the audit:

1. Identify the highest-impact prompt problems.
2. Explain why they occur.
3. Refactor the prompt architecture.
4. Improve prompts where necessary.
5. Improve context construction where necessary.
6. Improve intent detection where necessary.
7. Improve structured output where appropriate.
8. Add validation where necessary.
9. Add evaluation/test cases.
10. Preserve existing functionality.

Do not simply make prompts longer.

A longer prompt does not automatically mean a better prompt.

Prefer:

- Clear instruction hierarchy
- Explicit constraints
- Structured context
- Intent-aware prompting
- Evidence-aware reasoning
- Strong output contracts
- Minimal ambiguity
- Deterministic application logic where possible

---

# 17. Final Audit Report

After reviewing the system, provide:

## AI Architecture

Explain exactly how GutGood currently generates AI responses.

## Prompt Architecture

Show:

```text
System Instructions
        ↓
Intent
        ↓
User Context
        ↓
Conversation Context
        ↓
Feature Instructions
        ↓
LLM
        ↓
Structured Response
        ↓
Validation
        ↓
UI
```

Adapt this to the actual implementation.

## Critical Problems

List the most important issues with severity:

- P0 — Critical
- P1 — High
- P2 — Medium
- P3 — Low

## Prompt Problems

Identify:

- Redundant instructions
- Conflicting instructions
- Missing instructions
- Weak instructions
- Poor prompt boundaries
- Incorrect context
- Hallucination risks

## AI Behavior Problems

Identify:

- Intent failures
- Personalization failures
- Insight failures
- Safety issues
- Repetition
- Generic answers
- Over-analysis
- Under-analysis

## Recommended Architecture

Show the improved AI architecture.

## Prompt Improvements

Show the before/after approach and explain why each change improves reliability.

## Evaluation Suite

Create a practical test suite for validating future prompt changes.

## Implementation

Implement the highest-value improvements directly in the existing codebase.

---

# Final Engineering Principle

Treat GutGood's prompts as **production software**, not just text.

Do not optimize prompts based on intuition alone.

Always ask:

> What behavior are we trying to produce?

> What data does the model actually have?

> What assumptions is the model making?

> What happens when the required data is missing?

> How do we know the response is correct?

> How do we prevent the model from inventing evidence?

> How do we keep behavior consistent as the application grows?

The final GutGood AI system should be:

**Accurate + Evidence-aware + Personalized + Safe + Consistent + Efficient + Maintainable**

while preserving the application's existing functionality and product intent.