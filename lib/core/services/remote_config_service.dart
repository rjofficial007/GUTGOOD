import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gutgood/core/constants/api_constants.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class RemoteConfigService {
  static RemoteConfigService get instance => sl<RemoteConfigService>();
  Future<void> init();
  String get openAIModel;
  String get aiProxyUrl;
  bool get isForceUpdateApp;
}

class RemoteConfigServiceImpl implements RemoteConfigService {
  RemoteConfigServiceImpl({required FirebaseRemoteConfig remoteConfig})
    : _remoteConfig = remoteConfig;
  final FirebaseRemoteConfig _remoteConfig;

  static const String _defaultOpenAIModel = 'gpt-4o-mini';

  @override
  Future<void> init() async {
    try {
      // NOTE: No secrets in defaults. The OpenAI key is intentionally NOT here —
      // PRD §3d forbids shipping it to devices. All AI traffic goes through the
      // aiProxy Cloud Function which authenticates the caller server-side.
      await _remoteConfig.setDefaults({
        'openai_model': _defaultOpenAIModel,
        'ai_proxy_url': ApiConstants.aiProxyUrl,
        'is_force_update': false,
      });

      if (kDebugMode) {
        AppLogger.remoteConfig(
          'Remote Config: Skipping fetch in Debug Mode (defaults active).',
        );
        return;
      }

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await _remoteConfig.fetchAndActivate();
      AppLogger.remoteConfig('Remote Config: Initialized and fetched.');
    } catch (e) {
      AppLogger.error('RemoteConfigService: Initialization failed', error: e);
    }
  }

  @override
  String get openAIModel {
    final model = _remoteConfig.getString('openai_model');
    return model.isEmpty ? _defaultOpenAIModel : model;
  }

  @override
  String get aiProxyUrl {
    if (kDebugMode) return ApiConstants.aiProxyUrl;
    final url = _remoteConfig.getString('ai_proxy_url');
    return url.isEmpty ? ApiConstants.aiProxyUrl : url;
  }

  @override
  bool get isForceUpdateApp {
    if (kDebugMode) return false;
    return _remoteConfig.getBool('is_force_update');
  }
}
