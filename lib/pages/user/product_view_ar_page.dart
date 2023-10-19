import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ProductViewARPage extends StatefulWidget {
  String product3DImage;

  ProductViewARPage({super.key, required this.product3DImage});

  @override
  State<ProductViewARPage> createState() => _ProductViewARPageState();
}

class _ProductViewARPageState extends State<ProductViewARPage> {
  late ArCoreController arCoreController;

  @override
  void initState() {
    super.initState();
    _initAR();
  }

  void _initAR() async {
    // Check and request camera permission
    await _requestCameraPermission();

    // Initialize AR
    arCoreController = ArCoreController(
      id: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      // Handle the case where the user did not grant permission.
      print('Camera permission not granted');
    }
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    _add3DModel();
  }

  void _add3DModel() {
    // Load and display 3D model
    final node = ArCoreReferenceNode(
      name: 'ar_node',
      object3DFileName: widget.product3DImage,
      position: vector.Vector3(0, 0, -1.5), // Adjust position as needed
      rotation: vector.Vector4(0, 0, 0, 0), // Adjust rotation as needed
      scale: vector.Vector3(1.0, 1.0, 1.0), // Adjust scale as needed
    );

    arCoreController.addArCoreNode(node);
  }

  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArCoreView(
        onArCoreViewCreated: _onArCoreViewCreated,
      ),
    );
  }
}
