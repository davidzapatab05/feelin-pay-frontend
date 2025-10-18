import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/system_controller.dart';

class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemController>(
      builder: (context, systemController, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: systemController.hasInternetConnection
                ? Colors.green
                : Colors.red,
            boxShadow: [
              BoxShadow(
                color:
                    (systemController.hasInternetConnection
                            ? Colors.green
                            : Colors.red)
                        .withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}
