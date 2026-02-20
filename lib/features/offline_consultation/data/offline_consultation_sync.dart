import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'offline_consultation_db.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineConsultationSync {
  final ApiClient _apiClient;
  bool _isSyncing = false;

  OfflineConsultationSync(this._apiClient);

  Future<void> syncPending() async {
    if (_isSyncing) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      AppLogger.info('Sync', 'No internet connection, skipping sync.');
      return;
    }

    _isSyncing = true;
    try {
      final pending = await OfflineConsultationDb.instance.getPending();
      if (pending.isEmpty) {
        AppLogger.info('Sync', 'No pending consultations to sync.');
        return;
      }

      AppLogger.info('Sync', 'Found ${pending.length} pending offline consultations.');

      for (final consultation in pending) {
        final id = consultation['id'] as String;
        try {
          final formDataMap = {
            'chiefComplaint': consultation['chiefComplaint'],
            'symptomsDescription': consultation['symptomsDescription'],
          };

          final mediaPath = consultation['mediaPath'] as String?;
          final mediaType = consultation['mediaType'] as String?;

          if (mediaPath != null && mediaType != null && File(mediaPath).existsSync()) {
            final fileField = mediaType == 'video' ? 'video' : 'photo';
            formDataMap[fileField] = await MultipartFile.fromFile(mediaPath);
          }

          final formData = FormData.fromMap(formDataMap);

          AppLogger.info('Sync', 'Uploading consultation $id...');
          await _apiClient.dio.post(
            '${ApiConstants.offlineConsultationEndpoint}/submit',
            data: formData,
          );

          await OfflineConsultationDb.instance.updateStatus(id, 'synced');
          AppLogger.info('Sync', 'Successfully synced consultation $id');
        } catch (e) {
          AppLogger.error('Sync', 'Failed to sync consultation $id', e);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
