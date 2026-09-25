import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../data/services/backup_service.dart';

/// نتيجة عملية نسخ احتياطي/استعادة جاهزة للعرض على الواجهة.
sealed class BackupOutcome {
  const BackupOutcome();

  /// رسالة عربية جاهزة للعرض في SnackBar.
  String get message;

  /// هل تنبثق نافذة الإعدادات بعد النجاح؟ (عمليات الاستعادة).
  bool get popsSheet => false;
}

class BackupSuccess extends BackupOutcome {
  const BackupSuccess(this.message, {this.popsSheet = false});

  @override
  final String message;

  @override
  final bool popsSheet;
}

/// رسالة محايدة (ليست نجاحًا ولا فشلًا) مثل "لا توجد نسخ متاحة".
class BackupNotice extends BackupOutcome {
  const BackupNotice(this.message);

  @override
  final String message;
}

class BackupError extends BackupOutcome {
  const BackupError(this.message);

  @override
  final String message;
}

/// حالة [BackupCubit] — تُستخدم لتعطيل الأزرار أثناء التنفيذ.
class BackupState extends Equatable {
  const BackupState({this.isBusy = false});

  final bool isBusy;

  @override
  List<Object?> get props => [isBusy];
}

/// يدير عمليات النسخ الاحتياطي والاستعادة والمزامنة السحابية،
/// ويعزل الواجهة عن [BackupService] ويوحّد تحويل الأخطاء لرسائل عربية.
class BackupCubit extends Cubit<BackupState> {
  BackupCubit(this._service) : super(const BackupState());

  final BackupService _service;

  /// إنشاء نسخة احتياطية داخل مجلد قاعدة البيانات.
  Future<BackupOutcome> createLocalBackup() => _run(
        () async {
          final path = await _service.createBackup();
          return BackupSuccess('تم إنشاء نسخة احتياطية: $path');
        },
        fallback: 'تعذر إنشاء النسخة الاحتياطية',
      );

  /// استعادة أحدث نسخة احتياطية محلية.
  Future<BackupOutcome> restoreLatestBackup() => _run(
        () async {
          final restored = await _service.restoreLatestBackup();
          if (!restored) return const BackupNotice('لا توجد نسخ احتياطية متاحة.');
          return const BackupSuccess(
            'تمت استعادة النسخة الاحتياطية بنجاح.',
            popsSheet: true,
          );
        },
        fallback: 'تعذرت الاستعادة',
      );

  /// تصدير نسخة إلى مجلد التنزيلات (أندرويد) أو مستندات التطبيق.
  Future<BackupOutcome> exportToDownloads() => _run(
        () async {
          final location = await _service.createBackupInDownloads();
          if (location == null) {
            return const BackupNotice('تعذر تصدير النسخة الاحتياطية.');
          }
          return BackupSuccess('تم تصدير نسخة احتياطية إلى $location.');
        },
        fallback: 'تعذر تصدير النسخة الاحتياطية',
      );

  /// رفع نسخة احتياطية إلى Supabase Storage.
  Future<BackupOutcome> uploadToCloud() => _run(
        () async {
          final name = await _service.uploadBackupToCloud();
          return BackupSuccess('تم رفع النسخة الاحتياطية إلى السحابة: $name');
        },
        fallback: 'تعذرت المزامنة السحابية',
      );

  /// سحب أحدث نسخة من السحابة واستعادتها محليًا.
  Future<BackupOutcome> downloadAndRestoreFromCloud() => _run(
        () async {
          final count = await _service.downloadLatestFromCloud();
          return BackupSuccess(
            'تم سحب أحدث نسخة واستعادتها ($count نسخة في السحابة).',
            popsSheet: true,
          );
        },
        fallback: 'تعذرت المزامنة السحابية',
      );

  Future<BackupOutcome> _run(
    Future<BackupOutcome> Function() action, {
    required String fallback,
  }) async {
    emit(const BackupState(isBusy: true));
    try {
      return await action();
    } catch (e) {
      if (e is Failure || e is AppException) {
        return BackupError(Failure.from(e).message);
      }
      return BackupError(safeErrorMessage(fallback, e));
    } finally {
      if (!isClosed) emit(const BackupState());
    }
  }
}
