/// App-owned navigation capability used by notification infrastructure.
///
/// The core notification service only needs to request a route. It must not
/// import GoRouter or the app router implementation to do so.
abstract interface class NotificationNavigationPort {
  void push(String path);
}
