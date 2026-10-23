/// The new average after adding [newRating] to [count] existing ratings that
/// average [currentAverage]. Rounded to two decimals.
double addRating({required double currentAverage, required int count, required int newRating}) {
  if (count <= 0) return newRating.toDouble();
  final average = (currentAverage * count + newRating) / (count + 1);
  return (average * 100).roundToDouble() / 100;
}
