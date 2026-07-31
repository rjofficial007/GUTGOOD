# Project Dependencies

This document explains the choice and purpose of key packages used in the GutGood project as defined in `pubspec.yaml`.

## Core Infrastructure
| Package | Purpose | Why this one? |
| --- | --- | --- |
| `firebase_core` | Firebase base SDK. | Standard for Google-backed backends. |
| `cloud_firestore` | NoSQL real-time DB. | Excellent offline support and real-time listeners. |
| `firebase_auth` | User identity. | Secure, multi-provider auth with zero boilerplate. |
| `get_it` | Service Locator / DI. | Lightweight, high-performance, and non-intrusive. |
| `provider` | State Management. | Flutter-idiomatic and easy to scale with ChangeNotifiers. |
| `go_router` | Declarative Routing. | Deep-linking support and nested shell navigation. |

## AI & Data Processing
| Package | Purpose | Note |
| --- | --- | --- |
| `dio` | HTTP Client. | Used for AI Proxy streaming and file uploads. |
| `mobile_scanner` | Barcode/QR scanning. | Fast, cross-platform, and supports manual camera control. |
| `intl` | Formatting. | Used for date parsing and currency localization. |

## UI & User Experience
| Package | Purpose | Note |
| --- | --- | --- |
| `flutter_animate` | Narrative animations. | High-performance, declarative animation chains. |
| `cached_network_image`| Image caching. | Essential for scanning history and profile pictures. |
| `lucide_icons_flutter`| Vector icons. | Consistent, modern icon set (Material 3 style). |
| `shimmer` | Loading placeholders. | Enhances perceived performance during data fetching. |
| `flutter_markdown_plus`| AI response rendering. | Supports rich formatting, code blocks, and links. |

## Device & Platform Services
| Package | Purpose | Note |
| --- | --- | --- |
| `purchases_flutter` | Subscriptions. | RevenueCat wrapper; simplifies IAP logic across platforms. |
| `shared_preferences` | Local settings. | Storing onboarding flags and theme preferences. |
| `image_picker` | Gallery/Camera access. | Standard utility for image selection. |
| `permission_handler` | System permissions. | Unified API for requesting Camera/Gallery access. |
| `package_info_plus` | App versioning. | Used for "Check for Updates" logic. |

---

## Dependency Management Best Practices
1. **Pinned Versions:** All critical Firebase and Platform dependencies are pinned with `^` to allow for non-breaking updates while preventing major version mismatch.
2. **Lazy Initialization:** Services are registered as `LazySingleton` in `GetIt` to minimize startup time.
3. **Environment Separation:** The `USE_FIREBASE_EMULATOR` flag allows developers to work against local Firebase Emulator Suite without affecting production data.
