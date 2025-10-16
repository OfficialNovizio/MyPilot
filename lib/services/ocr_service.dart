
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractTextFromFile(String path) async {
    final input = InputImage.fromFilePath(path);
    final res = await _recognizer.processImage(input);
    return res.text;
  }

  Future<List<String>> pickAndExtractTexts({bool camera = false}) async {
    final picker = ImagePicker();
    final List<XFile> files = [];

    if (camera) {
      final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (img != null) files.add(img);
    } else {
      final imgs = await picker.pickMultiImage(imageQuality: 85);
      files.addAll(imgs);
    }

    final out = <String>[];
    for (final f in files) {
      out.add(await extractTextFromFile(f.path));
    }
    return out;
  }

  void dispose() => _recognizer.close();
}
