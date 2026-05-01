import 'package:chucker_flutter/src/models/log.dart';
import 'package:chucker_flutter/src/view/helper/colors.dart';
import 'package:flutter/material.dart';

/// [LogsListingTabView] shows the listing of logs
class LogsListingTabView extends StatelessWidget {
  /// [LogsListingTabView] shows the listing of logs
  const LogsListingTabView({
    required this.logs,
    required this.onDelete,
    super.key,
  });

  /// The list of [Log] to be shown
  final List<Log> logs;

  /// Callback to delete a log
  final void Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text('No logs found'),
      );
    }
    return ListView.separated(
      itemBuilder: (_, i) {
        final log = logs[i];
        return ListTile(
          leading: Icon(
            _getIcon(log.level),
            color: _getColor(log.level),
          ),
          title: Text(
            log.message,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(log.time.toString()),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => onDelete(log.time.toString()),
          ),
        );
      },
      separatorBuilder: (_, __) => const Divider(),
      itemCount: logs.length,
    );
  }

  IconData _getIcon(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Icons.info;
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
    }
  }

  Color _getColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.green;
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }
}
