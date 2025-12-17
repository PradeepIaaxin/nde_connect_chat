class TextUtils {
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() +
          word.substring(1).toLowerCase();
    }).join(' ');
  }
}
