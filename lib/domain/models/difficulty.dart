/// Canonical content levels, serialized as integers rather than enum indexes.
enum Difficulty {
  easy(1),
  medium(2),
  hard(3);

  final int value;

  const Difficulty(this.value);

  factory Difficulty.fromValue(int value) {
    return switch (value) {
      1 => easy,
      2 => medium,
      3 => hard,
      _ => throw RangeError.range(value, 1, 3, 'difficulty'),
    };
  }

  factory Difficulty.fromJson(Object? value) {
    if (value is! int) {
      throw const FormatException('Expected an integer for difficulty');
    }
    return Difficulty.fromValue(value);
  }

  int toJson() => value;
}
