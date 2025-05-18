import 'package:flutter/material.dart';

/// Loading indicator widget to show while content is loading
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool overlay;
  final Color? color;
  
  const LoadingIndicator({
    Key? key,
    this.message,
    this.overlay = false,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final loadingWidget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: color ?? Theme.of(context).primaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
    
    if (overlay) {
      return Stack(
        children: [
          ModalBarrier(
            color: Colors.black.withOpacity(0.3),
            dismissible: false,
          ),
          loadingWidget,
        ],
      );
    } else {
      return loadingWidget;
    }
  }
}

/// Widget that shows loading indicator when isLoading is true,
/// otherwise shows the provided child.
class LoadingContainer extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;
  final bool overlay;
  final Color? color;
  
  const LoadingContainer({
    Key? key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
    this.overlay = false,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }
    
    if (overlay) {
      return Stack(
        children: [
          child,
          LoadingIndicator(
            message: loadingMessage,
            overlay: true,
            color: color,
          ),
        ],
      );
    } else {
      return LoadingIndicator(
        message: loadingMessage,
        color: color,
      );
    }
  }
}
