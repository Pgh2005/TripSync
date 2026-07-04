enum MarkerFilter { all, mine, shared }

extension MarkerFilterX on MarkerFilter {
  String get label {
    switch (this) {
      case MarkerFilter.all:
        return 'همه';
      case MarkerFilter.mine:
        return 'فقط من';
      case MarkerFilter.shared:
        return 'اشتراکی';
    }
  }
}
