/// Normaliza texto para búsquedas: minúsculas y sin tildes.
/// "Migraña" y "migrana" deben encontrar lo mismo.
abstract final class SearchNormalizer {
  static const Map<String, String> _accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };

  static String normalize(String value) {
    final lower = value.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }
}
