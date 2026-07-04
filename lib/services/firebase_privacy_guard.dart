class FirebasePrivacyGuard {
  FirebasePrivacyGuard._();

  static const List<String> forbiddenKeys = [
    'activities',
    'activityLogs',
    'rawActivities',
    'rawActivityLogs',
    'activityRows',
    'records',
    'sessions',
    'appName',
    'appNames',
    'windowTitle',
    'windowTitles',
    'title',
    'url',
    'urls',
    'website',
    'websites',
    'fileName',
    'fileNames',
    'processPath',
    'executablePath',
  ];

  static void validateDailySummaryPayload(Map<String, dynamic> payload) {
    final blockedPaths = <String>[];

    void scan(dynamic value, String path) {
      if (value is Map) {
        for (final entry in value.entries) {
          final key = entry.key.toString();
          final nextPath = path.isEmpty ? key : '$path.$key';

          if (_isForbiddenKey(key)) {
            blockedPaths.add(nextPath);
          }

          scan(entry.value, nextPath);
        }
      } else if (value is List) {
        for (var index = 0; index < value.length; index++) {
          scan(value[index], '$path[$index]');
        }
      }
    }

    scan(payload, '');

    if (blockedPaths.isNotEmpty) {
      throw StateError(
        'Privacy guard blocked Firebase sync. Forbidden fields: '
        '${blockedPaths.join(', ')}',
      );
    }

    final privacy = payload['privacy'];

    if (privacy is! Map) {
      throw StateError(
        'Privacy guard blocked Firebase sync: missing privacy map.',
      );
    }

    if (privacy['summaryOnly'] != true) {
      throw StateError(
        'Privacy guard blocked Firebase sync: summaryOnly must be true.',
      );
    }

    if (privacy['rawActivityLogsSynced'] != false) {
      throw StateError(
        'Privacy guard blocked Firebase sync: rawActivityLogsSynced must be false.',
      );
    }

    if (privacy['appNamesSynced'] != false) {
      throw StateError(
        'Privacy guard blocked Firebase sync: appNamesSynced must be false.',
      );
    }

    if (privacy['windowTitlesSynced'] != false) {
      throw StateError(
        'Privacy guard blocked Firebase sync: windowTitlesSynced must be false.',
      );
    }
  }

  static bool _isForbiddenKey(String key) {
    final normalized = key.trim().toLowerCase();

    return forbiddenKeys.any(
      (forbiddenKey) => normalized == forbiddenKey.toLowerCase(),
    );
  }
}
