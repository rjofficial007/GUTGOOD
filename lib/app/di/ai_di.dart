import 'package:gutgood/core/ai/classification/ai_classifier_service.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/infrastructure/ai/ai_proxy_client.dart';

/// Registers the SDK-neutral AI contract and its concrete infrastructure
/// implementation.
void initAiDI() {
  sl
    ..registerLazySingleton<AiClient>(() => AiProxyClient(dio: sl(), auth: sl(), config: sl(), analyticsService: sl(), crashlyticsService: sl()))
    ..registerLazySingleton<AiClassifierService>(() => AiClassifierServiceImpl(aiService: sl()));
}
