 
import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoginButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomLoginButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  _CustomLoginButtonState createState() => _CustomLoginButtonState();
}

class _CustomLoginButtonState extends State<CustomLoginButton> {
  double _scaleFactor = 1.0;
  Color _buttonColor = MainColors.primaryColor;
  final Color _pressedColor = MainColors.primaryColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,
      onTapDown: (_) {
        setState(() {
          _scaleFactor = 0.95;
          _buttonColor = _pressedColor;
        });
      },
      onTapUp: (_) {
        setState(() {
          _scaleFactor = 1.0;
          _buttonColor = MainColors.primaryColor;
        });
      },
      onTapCancel: () {
        setState(() {
          _scaleFactor = 1.0;
          _buttonColor = MainColors.primaryColor;
        });
      },
      child: AnimatedScale(
        scale: _scaleFactor,
        duration: const Duration(milliseconds: 20),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(30),
            splashColor: Colors.white.withOpacity(0.4),
            highlightColor: Colors.white.withOpacity(0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: _buttonColor,
                borderRadius: BorderRadius.circular(10),
              ),
              // padding: const EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              height: 60,
              width: double.infinity,
              child: Center(
                child: widget.isLoading
                    ? Lottie.asset(
                        'assets/Lottie/Lib/loading.json',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      )
                    : Text(
                        widget.text,
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
