enum ExpenseCategory { food, transport, hotel, shopping, entertainment, other }

extension ExpenseCategoryX on ExpenseCategory {
  String get value {
    switch (this) {
      case ExpenseCategory.food:
        return 'food';
      case ExpenseCategory.transport:
        return 'transport';
      case ExpenseCategory.hotel:
        return 'hotel';
      case ExpenseCategory.shopping:
        return 'shopping';
      case ExpenseCategory.entertainment:
        return 'entertainment';
      case ExpenseCategory.other:
        return 'other';
    }
  }

  String get labelFa {
    switch (this) {
      case ExpenseCategory.food:
        return 'غذا';
      case ExpenseCategory.transport:
        return 'حمل و نقل';
      case ExpenseCategory.hotel:
        return 'اقامت';
      case ExpenseCategory.shopping:
        return 'خرید';
      case ExpenseCategory.entertainment:
        return 'تفریح';
      case ExpenseCategory.other:
        return 'سایر';
    }
  }

  static ExpenseCategory fromString(String? value) {
    switch (value) {
      case 'food':
        return ExpenseCategory.food;
      case 'transport':
        return ExpenseCategory.transport;
      case 'hotel':
        return ExpenseCategory.hotel;
      case 'shopping':
        return ExpenseCategory.shopping;
      case 'entertainment':
        return ExpenseCategory.entertainment;
      default:
        return ExpenseCategory.other;
    }
  }
}
