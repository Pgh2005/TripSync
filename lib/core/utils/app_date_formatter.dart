import 'package:shamsi_date/shamsi_date.dart';

class AppDateFormatter {
  static String toJalali(DateTime date) {
    final jDate = Jalali.fromDateTime(date);

    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    return '${jDate.day} ${months[jDate.month - 1]} ${jDate.year}';
  }

  static String toJalaliShort(DateTime date) {
    final jDate = Jalali.fromDateTime(date);

    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    return '${jDate.day} ${months[jDate.month - 1]}';
  }
}
