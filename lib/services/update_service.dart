import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  // ⚠️ ЗАМЕНИ на свой репозиторий
  static const String repoOwner = 'ak3301389';
  static const String repoName = 'monkeybudget';

  /// Проверяет, есть ли новая версия на GitHub
  /// Возвращает Map с данными о новой версии или null
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      // 1. Получаем текущую версию приложения
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // например, "4.8.0"
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      print('📱 Текущая версия: $currentVersion+$currentBuild');

      // 2. Запрашиваем последний релиз с GitHub
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
      final tagName = data['tag_name'] as String?; // например, "v4.8.0+121"
      final htmlUrl = data['html_url'] as String?;
      final body = data['body'] as String? ?? '';
      final publishedAt = data['published_at'] as String?;

      if (tagName == null || htmlUrl == null) {
        print('❌ Нет tag_name или html_url в ответе');
        return null;
      }

      print('📦 Последний релиз: $tagName');

      // 3. Парсим версию из tag (формат: "v4.8.0+121" или "v4.8.0.121")
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

      // 4. Сравниваем с текущей
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

      // 5. Возвращаем данные о новой версии
      return {
        'version': '$major.$minor.$patch',
        'build': build,
        'tag': tagName,
        'url': htmlUrl,
        'notes': body,
        'publishedAt': publishedAt,
      };
    } catch (e) {
      print('❌ Ошибка проверки обновлений: $e');
      return null;
    }
  }
}
