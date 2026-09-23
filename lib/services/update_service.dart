import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String repoOwner = 'ak3301389';
  static const String repoName = 'monkeybudget';

  /// Проверяет, есть ли новая версия на GitHub
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      print('📱 Текущая версия: $currentVersion+$currentBuild');

      final url = Uri.parse(
        'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
      );
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github+json',
      });

      if (response.statusCode != 200) {
        print('❌ GitHub API вернул ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String?;
      final htmlUrl = data['html_url'] as String?;
      final body = data['body'] as String? ?? '';
      final assets = data['assets'] as List?;

      if (tagName == null || htmlUrl == null || assets == null) {
        print('❌ Нет tag_name/html_url/assets');
        return null;
      }

      print('📦 Последний релиз: $tagName');

      // Ищем APK-файл в assets
      String? apkUrl;
      for (var asset in assets) {
        final name = asset['name'] as String?;
        if (name != null && name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      if (apkUrl == null) {
        print('❌ APK не найден в релизе');
        return null;
      }

      // Парсим версию
      final versionMatch =
          RegExp(r'v?(\d+)\.(\d+)\.(\d+)[+.](\d+)').firstMatch(tagName);
      if (versionMatch == null) {
        print('❌ Не удалось распарсить версию из "$tagName"');
        return null;
      }

      final major = int.parse(versionMatch.group(1)!);
      final minor = int.parse(versionMatch.group(2)!);
      final patch = int.parse(versionMatch.group(3)!);
      final build = int.parse(versionMatch.group(4)!);

      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final currentMajor = currentParts.isNotEmpty ? currentParts[0] : 0;
      final currentMinor = currentParts.length > 1 ? currentParts[1] : 0;
      final currentPatch = currentParts.length > 2 ? currentParts[2] : 0;

      final isNewer = (major > currentMajor) ||
          (major == currentMajor && minor > currentMinor) ||
          (major == currentMajor &&
              minor == currentMinor &&
              patch > currentPatch) ||
          (major == currentMajor &&
              minor == currentMinor &&
              patch == currentPatch &&
              build > currentBuild);

      if (!isNewer) {
        print('✅ Установлена последняя версия');
        return null;
      }

      return {
        'version': '$major.$minor.$patch',
        'build': build,
        'tag': tagName,
        'url': htmlUrl,
        'apkUrl': apkUrl,
        'notes': body,
      };
    } catch (e) {
      print('❌ Ошибка проверки обновлений: $e');
      return null;
    }
  }

  /// Скачивает APK и открывает установщик
  /// Возвращает true, если всё ок
  static Future<bool> downloadAndInstall(
    String apkUrl, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // 1. Папка для скачивания
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/update.apk';
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 2. Скачиваем через dio
      final dio = Dio();
      await dio.download(
        apkUrl,
        filePath,
        onReceiveProgress: onProgress,
      );

      print('✅ APK скачан: $filePath');

      // 3. Открываем установщик
      final result = await OpenFilex.open(filePath);
      print('📦 Результат открытия: ${result.type} - ${result.message}');

      return result.type == ResultType.done;
    } catch (e) {
      print('❌ Ошибка скачивания/установки: $e');
      return false;
    }
  }
}
