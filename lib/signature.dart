import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SignatureScreen extends StatefulWidget {
  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  final Uuid uuid = Uuid();

  Future<void> _saveSignature() async {
    try {
      // Capturar firma como imagen
      RenderSignaturePad boundary = _signaturePadKey.currentContext!
          .findRenderObject()! as RenderSignaturePad;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Guardar imagen temporalmente
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/signature.png').create();
      await file.writeAsBytes(pngBytes);

      // Generar un nombre de archivo único
      String uniqueFileName = 'signature_${uuid.v4()}.png';

      // Subir imagen a Supabase
      final supabase = Supabase.instance.client;
      await supabase.storage.from('signatures').upload(uniqueFileName, file);

      // Obtener la URL de la imagen
      final imageUrlResponse =
          supabase.storage.from('signatures').getPublicUrl(uniqueFileName);

      // Guardar URL en la tabla
      await supabase.from('prueba').insert({'imagenUrl': imageUrlResponse});

      print('Signature URL saved: $imageUrlResponse');
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Signature Pad')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SfSignaturePad(
                key: _signaturePadKey,
                backgroundColor: Colors.white,
                strokeColor: Colors.black,
                minimumStrokeWidth: 1.0,
                maximumStrokeWidth: 4.0,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSignature,
              child: Text('Save Signature'),
            ),
          ],
        ),
      ),
    );
  }
}
