abstract final class JsonValue {
  static int asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return num.tryParse(value?.toString() ?? '')?.toInt() ?? fallback;
  }
}
