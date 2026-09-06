import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DisasterSearchScreen extends StatefulWidget {
  final String disasterType;

  const DisasterSearchScreen({super.key, required this.disasterType});

  @override
  State<DisasterSearchScreen> createState() => _DisasterSearchScreenState();
}

class _DisasterSearchScreenState extends State<DisasterSearchScreen> with SingleTickerProviderStateMixin {
  bool _helpFound = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate finding help after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _helpFound = true;
        });
        _pulseController.stop();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.bgDark : AppTheme.bgLight;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    Color primaryColor;
    IconData iconData;
    
    switch(widget.disasterType.toLowerCase()) {
      case 'flood':
        primaryColor = AppTheme.primaryBlueLight;
        iconData = Icons.flood;
        break;
      case 'cyclone':
        primaryColor = AppTheme.visionPurple;
        iconData = Icons.cyclone;
        break;
      default:
        primaryColor = Colors.orange;
        iconData = Icons.warning_amber_rounded;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_helpFound) ...[
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.2),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 2),
                    ),
                    child: Icon(iconData, size: 80, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 60),
                Text(
                  "Broadcasting ${widget.disasterType} Alert",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Searching for nearest Govt. Disaster Control, Army Forces, and specialized response units...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                CircularProgressIndicator(color: primaryColor),
              ] else ...[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.healthyGreen,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.healthyGreen.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(Icons.check_circle, size: 80, color: Colors.white),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 40),
                Text(
                  "Help Dispatched!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Nearest Disaster Control teams and available army forces have been notified with your exact GPS coordinates and are en route.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Return to Dashboard", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
