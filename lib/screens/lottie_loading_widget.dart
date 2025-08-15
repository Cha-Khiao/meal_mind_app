import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final String animationPath;
  
  const LottieLoadingWidget({
    Key? key,
    this.message,
    this.size = 150,
    this.animationPath = 'assets/animations/loading_food.json',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            animationPath,
            width: size,
            height: size,
            repeat: true,
            reverse: false,
            animate: true,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  SizedBox(height: 16),
                  Icon(
                    Icons.fastfood,
                    size: 60,
                    color: Colors.orange.shade600,
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 24),
          if (message != null)
            Text(
              message!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 8),
          Text(
            'กรุณารอสักครู่...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}