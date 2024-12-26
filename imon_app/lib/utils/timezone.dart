import 'package:intl/intl.dart';

String formatDateWithTimeZone(DateTime dateTime) {
  final localDateTime = dateTime.toLocal();
  final offset = localDateTime.timeZoneOffset.inHours;

  String timeZoneAbbreviation;
  switch (offset) {
    case 7:
      timeZoneAbbreviation = 'WIB';
      break;
    case 8:
      timeZoneAbbreviation = 'WITA';
      break;
    case 9:
      timeZoneAbbreviation = 'WIT';
      break;
    default:
      timeZoneAbbreviation = 'GMT${offset >= 0 ? '+' : ''}$offset';
  }

  final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(localDateTime);

  return '$formattedDate $timeZoneAbbreviation';
}


String aDayInterval(){
  DateTime now = DateTime.now();
  DateTime startOfDay = DateTime(now.year, now.month, now.day);

  String interval = '${now.difference(startOfDay).inMinutes}m';
  return interval;
}

String minuteInterval(int minutes) {
  DateTime now = DateTime.now();
  DateTime fiveMinutesAgo = now.subtract(Duration(minutes: minutes));

  String interval = '${now.difference(fiveMinutesAgo).inMinutes}m';
  return interval;
}


String getCurrentDateTime() {
  DateTime now = DateTime.now().toUtc();
  return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(now);
}

String formatDateString(DateTime inputDate) {
  String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(inputDate);
  return formattedDate;
}