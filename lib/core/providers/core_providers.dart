import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_interceptor.dart';
import '../auth/token_storage.dart';
import '../ws/ws_manager.dart';

const _apiBaseUrl = 'http://localhost:8082';
const _wsBaseUrl = 'ws://localhost:8083';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final wsManagerProvider = Provider<WsManager>((ref) {
  final manager = WsManager(_wsBaseUrl);
  ref.onDispose(() => manager.dispose());
  return manager;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  final interceptor = AuthInterceptor(
    tokenStorage: tokenStorage,
    baseUrl: _apiBaseUrl,
    onRefreshFailed: () async {
      await ref.read(tokenStorageProvider).clearAll();
    },
  );
  return ApiClient(baseUrl: _apiBaseUrl, interceptors: [interceptor]);
});
