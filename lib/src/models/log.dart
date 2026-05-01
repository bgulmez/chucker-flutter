/// [LogLevel] is the level of log
enum LogLevel {
  /// [info] is the level for information logs
  info,

  /// [debug] is the level for debug logs
  debug,

  /// [warning] is the level for warning logs
  warning,

  /// [error] is the level for error logs
  error,
}

/// [Log] is the model for logs
class Log {
  /// [Log] is the model for logs
  Log({
    required this.message,
    required this.level,
    required this.time,
  });

  /// [message] is the log message
  final String message;

  /// [level] is the log level
  final LogLevel level;

  /// [time] is the log time
  final DateTime time;

  /// Convert [Log] to JSON.
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'level': level.index,
      'time': time.toIso8601String(),
    };
  }

  /// Convert JSON to [Log]
  factory Log.fromJson(Map<String, dynamic> json) => Log(
        message: json['message'] as String,
        level: LogLevel.values[json['level'] as int],
        time: DateTime.parse(json['time'] as String),
      );
}
