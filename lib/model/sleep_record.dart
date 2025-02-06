class SleepRecord {
  final int id;
  final int userId;
  final DateTime start;
  final DateTime end;
  final bool nap;
  final int totalInBedTimeMilli;
  final int totalAwakeTimeMilli;
  final int totalLightSleepTimeMilli;
  final int totalSlowWaveSleepTimeMilli;
  final int totalRemSleepTimeMilli;

  SleepRecord({
    required this.id,
    required this.userId,
    required this.start,
    required this.end,
    required this.nap,
    required this.totalInBedTimeMilli,
    required this.totalAwakeTimeMilli,
    required this.totalLightSleepTimeMilli,
    required this.totalSlowWaveSleepTimeMilli,
    required this.totalRemSleepTimeMilli,
  });

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      id: json['id'],
      userId: json['user_id'],
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      nap: json['nap'],
      totalInBedTimeMilli: json['score']['stage_summary']
          ['total_in_bed_time_milli'],
      totalAwakeTimeMilli: json['score']['stage_summary']
          ['total_awake_time_milli'],
      totalLightSleepTimeMilli: json['score']['stage_summary']
          ['total_light_sleep_time_milli'],
      totalSlowWaveSleepTimeMilli: json['score']['stage_summary']
          ['total_slow_wave_sleep_time_milli'],
      totalRemSleepTimeMilli: json['score']['stage_summary']
          ['total_rem_sleep_time_milli'],
    );
  }
}
