import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class AgriculturalLoadingIndicator extends StatelessWidget {
  final String statusMessage;

  const AgriculturalLoadingIndicator({
    super.key,
    this.statusMessage = 'Analyzing farm intelligence...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.sageLight.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.emerald),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String? message;
  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AgriculturalLoadingIndicator(
      statusMessage: message ?? 'Analyzing farm intelligence...',
    );
  }
}
