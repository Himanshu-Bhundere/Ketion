class Routes {
  static const String root = '/';

  static const String home = '/home';
  static const String search = '/search';
  static const String notes = '/notes';
  static const String reminders = '/reminders';
  static const String settings = '/settings';
  static const String settingsSync = '/settings/sync';

  static const String editorName = 'editor';
  static const String editor = '/editor/:pageId';

  static const String trashName = 'trash';
  static const String trash = '/trash';

  static const String alarmRingingName = 'alarm_ringing';
  static const String alarmRinging = '/alarm-ringing/:reminderId';
}
