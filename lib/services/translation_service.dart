import 'package:translator/translator.dart';

class TranslationService {
  final translator = GoogleTranslator();
  static const Duration _timeout = Duration(seconds: 15);

  Future<String> translateToThai(String text) async {
    try {
      final translation = await translator
          .translate(text, from: 'en', to: 'th')
          .timeout(_timeout);
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text; 
    }
  }

  Future<List<String>> translateListToThai(List<String> texts) async {
    try {

      List<Future<String>> translationFutures = texts.map((text) async {
        return await translator
            .translate(text, from: 'en', to: 'th')
            .timeout(_timeout)
            .then((translation) => translation.text)
            .catchError((e) {
          print('Translation error for "$text": $e');
          return text;
        });
      }).toList();
      
      return await Future.wait(translationFutures);
    } catch (e) {
      print('Batch translation error: $e');
      return texts; 
    }
  }
}