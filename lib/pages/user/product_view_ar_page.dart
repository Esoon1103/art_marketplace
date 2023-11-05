import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter/material.dart';

class ProductViewARPage extends StatefulWidget {
  final String product3DImage;

  const ProductViewARPage({super.key, required this.product3DImage});

  @override
  State<ProductViewARPage> createState() => _ProductViewARPageState();
}

class _ProductViewARPageState extends State<ProductViewARPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  ModelViewer(
        backgroundColor: const Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
        src: widget.product3DImage.toString(),
        alt: 'A 3d model testing',
        ar: true,
        loading: Loading.auto,
        reveal: Reveal.auto,
        autoRotate: true,
        disableZoom: false,
      ),
    );
  }
}
