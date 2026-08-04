// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "app_links", path: "../.packages/app_links-7.2.1"),
        .package(name: "cloud_firestore", path: "../.packages/cloud_firestore-6.8.0"),
        .package(name: "cloud_functions", path: "../.packages/cloud_functions-6.3.6"),
        .package(name: "device_info_plus", path: "../.packages/device_info_plus-12.3.0"),
        .package(name: "firebase_analytics", path: "../.packages/firebase_analytics-12.4.6"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-6.5.7"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.13.0"),
        .package(name: "firebase_crashlytics", path: "../.packages/firebase_crashlytics-5.2.7"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging-16.5.0"),
        .package(name: "firebase_remote_config", path: "../.packages/firebase_remote_config-6.5.6"),
        .package(name: "firebase_storage", path: "../.packages/firebase_storage-13.4.6"),
        .package(name: "flutter_image_compress_common", path: "../.packages/flutter_image_compress_common-1.1.1"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.2.0"),
        .package(name: "flutter_timezone", path: "../.packages/flutter_timezone-5.1.0"),
        .package(name: "google_sign_in_ios", path: "../.packages/google_sign_in_ios-6.3.0"),
        .package(name: "image_picker_ios", path: "../.packages/image_picker_ios-0.8.13+6"),
        .package(name: "in_app_review", path: "../.packages/in_app_review-2.0.12"),
        .package(name: "mobile_scanner", path: "../.packages/mobile_scanner-7.4.0"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-9.0.1"),
        .package(name: "permission_handler_apple", path: "../.packages/permission_handler_apple-9.4.10"),
        .package(name: "purchases_flutter", path: "../.packages/purchases_flutter-10.6.0"),
        .package(name: "share_plus", path: "../.packages/share_plus-12.0.2"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "sign_in_with_apple", path: "../.packages/sign_in_with_apple-8.1.0"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.3+1"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.4.1"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "app-links", package: "app_links"),
                .product(name: "cloud-firestore", package: "cloud_firestore"),
                .product(name: "cloud-functions", package: "cloud_functions"),
                .product(name: "device-info-plus", package: "device_info_plus"),
                .product(name: "firebase-analytics", package: "firebase_analytics"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-crashlytics", package: "firebase_crashlytics"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "firebase-remote-config", package: "firebase_remote_config"),
                .product(name: "firebase-storage", package: "firebase_storage"),
                .product(name: "flutter-image-compress-common", package: "flutter_image_compress_common"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "flutter-timezone", package: "flutter_timezone"),
                .product(name: "google-sign-in-ios", package: "google_sign_in_ios"),
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "in-app-review", package: "in_app_review"),
                .product(name: "mobile-scanner", package: "mobile_scanner"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "permission-handler-apple", package: "permission_handler_apple"),
                .product(name: "purchases-flutter", package: "purchases_flutter"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sign-in-with-apple", package: "sign_in_with_apple"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
