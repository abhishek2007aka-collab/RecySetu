import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads a time stored as a Firestore Timestamp, epoch milliseconds (seed
/// JSON) or an ISO string. Always returns UTC.
DateTime? readTime(Object? value) => switch (value) {
  Timestamp t => t.toDate().toUtc(),
  int ms => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
  String s => DateTime.tryParse(s)?.toUtc(),
  _ => null,
};

Timestamp? writeTime(DateTime? time) =>
    time == null ? null : Timestamp.fromDate(time.toUtc());

int? readInt(Object? value) => switch (value) {
  int i => i,
  num n => n.round(),
  _ => null,
};

double? readDouble(Object? value) => (value as num?)?.toDouble();

List<String> readStringList(Object? value) =>
    (value as List?)?.map((e) => '$e').toList() ?? const [];

/// Finds the enum value whose [wire] string matches [value], or [fallback].
T readEnum<T>(
  Object? value,
  List<T> values,
  String Function(T) wire,
  T fallback,
) {
  for (final v in values) {
    if (wire(v) == value) return v;
  }
  return fallback;
}
