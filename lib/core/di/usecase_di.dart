import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/send_message_stream_usecase.dart';

void initUseCaseDI() {
  sl
    ..registerLazySingleton(() => SendMessageStreamUseCase(sl()))
    ..registerLazySingleton(() => ProcessChatTagUseCase(firestoreService: sl(), appStateService: sl()));
}
