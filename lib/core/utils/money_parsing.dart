extension MoneyParsing on String {
  double toMoneyDouble() {
    return double.tryParse(replaceAll(',', '')) ?? 0;
  }
}
