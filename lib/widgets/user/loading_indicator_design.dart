import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class LoadingIndicatorDesign extends StatefulWidget {
  const LoadingIndicatorDesign({super.key});

  @override
  State<LoadingIndicatorDesign> createState() => _LoadingIndicatorDesignState();
}

class _LoadingIndicatorDesignState extends State<LoadingIndicatorDesign> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 50,
        child: LoadingIndicator(
          indicatorType: Indicator.ballPulse,
          colors: [Colors.blueGrey],
          strokeWidth: 1,
        ),
      ),
    );
  }
}
