import 'dart:convert';

import 'sleep_record.dart';

class SleepData {
  final List<SleepRecord> records;

  SleepData({required this.records});

  factory SleepData.fromJson(String jsonString) {
    final jsonData = json.decode(jsonString);
    final recordsList = (jsonData['records'] as List)
        .map((recordJson) => SleepRecord.fromJson(recordJson))
        .toList();

    return SleepData(records: recordsList);
  }

  int getTotalSleepTime() {
    return records.fold(
        0,
        (sum, record) =>
            sum + (record.totalInBedTimeMilli - record.totalAwakeTimeMilli));
  }

  int getTotalLightSleepTime() {
    return records.fold(
        0, (sum, record) => sum + record.totalLightSleepTimeMilli);
  }

  int getTotalSlowWaveSleepTime() {
    return records.fold(
        0, (sum, record) => sum + record.totalSlowWaveSleepTimeMilli);
  }

  int getTotalRemSleepTime() {
    return records.fold(
        0, (sum, record) => sum + record.totalRemSleepTimeMilli);
  }

  double convertMillisToHours(int millis) {
    return millis / (1000 * 60 * 60);
  }

  String formatForGemini() {
    return "Sleep Report: \n"
        "Total Sleep Time: ${convertMillisToHours(getTotalSleepTime()).toStringAsFixed(2)} hours\n"
        "Total Light Sleep Time: ${convertMillisToHours(getTotalLightSleepTime()).toStringAsFixed(2)} hours\n"
        "Total Slow Wave Sleep Time: ${convertMillisToHours(getTotalSlowWaveSleepTime()).toStringAsFixed(2)} hours\n"
        "Total REM Sleep Time: ${convertMillisToHours(getTotalRemSleepTime()).toStringAsFixed(2)} hours";
  }
}
