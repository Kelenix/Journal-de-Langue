/// Jour civil au format `AAAA-MM-JJ`, tel qu'attendu par le serveur.
String isoDate(DateTime day) {
  String padded(int value, int width) => value.toString().padLeft(width, '0');
  return '${padded(day.year, 4)}-${padded(day.month, 2)}-${padded(day.day, 2)}';
}
