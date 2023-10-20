import 'dart:typed_data';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' as vector;


class ProductViewARPage extends StatefulWidget {
  final String product3DImage;

  const ProductViewARPage({super.key, required this.product3DImage});

  @override
  State<ProductViewARPage> createState() => _ProductViewARPageState();
}

class _ProductViewARPageState extends State<ProductViewARPage> {
  ArCoreController? arCoreController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ModelViewer(
        backgroundColor: Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
        src: 'https://firebasestorage.googleapis.com/v0/b/artmarketplace-c750e.appspot.com/o/sellerProduct3DModel%2Ftyranno.glb?alt=media&token=2fd76a37-e31d-4839-95d2-7aea415eb6df',
        alt: 'A 3D model of an astronaut',
        ar: true,
        autoRotate: true,
        disableZoom: true,
      ),
    );
  }
}
