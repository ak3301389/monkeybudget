import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final String version;
  final int buildNumber;
  final String url;
  final String apkUrl;
  final String notes;

  const UpdateDialog({
    super.key,
    required this.version,
    required this.buildNumber,
    required this.url,
    required this.apkUrl,
    required this.notes,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0;
  String _status = '';

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _status = 'Скачивание...';
    });

    final ok = await UpdateService.downloadAndInstall(
      widget.apkUrl,
      onProgress: (received, total) {
        if (total > 0 && mounted) {
          setState(() {
            _progress = received / total;
          });
        }
      },
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        _status = 'Открыт установщик';
      });
    } else {
      setState(() {
        _isDownloading = false;
        _status = 'Ошибка. Попробуйте ещё раз';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Colors.teal),
          SizedBox(width: 8),
          Text('Доступно обновление'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Версия ${widget.version}+${widget.buildNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (widget.notes.isNotEmpty) ...[
              const Text('Что нового:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.notes, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
            ],
            if (_isDownloading) ...[
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 8),
              Text(
                '$_status ${_progress > 0 ? "${(_progress * 100).toStringAsFixed(0)}%" : ""}',
                style: const TextStyle(fontSize: 12),
              ),
            ] else if (_status.isNotEmpty) ...[
              Text(_status, style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Позже'),
          ),
        if (!_isDownloading)
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Скачать и установить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: _startUpdate,
          ),
      ],
    );
  }
}
