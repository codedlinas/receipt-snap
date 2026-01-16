import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background pattern
          _buildBackground(size),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Header
                  _buildHeader(context),
                  
                  const Spacer(),
                  
                  // Scan frame
                  _buildScanFrame(context),
                  
                  const Spacer(),
                  
                  // Capture buttons
                  _buildCaptureButtons(context),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(context),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CaptureBackgroundPainter(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.document_scanner_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Scan your receipt',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Take a photo or select from gallery',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScanFrame(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Stack(
        children: [
          // Corner decorations
          ..._buildCornerDecorations(),
          
          // Animated scan line
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Positioned(
                left: 20,
                right: 20,
                top: 20 + (_scanAnimation.value * 240),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Position receipt here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    const cornerLength = 32.0;
    const cornerThickness = 3.0;
    const cornerOffset = 12.0;

    return [
      // Top left
      Positioned(
        top: cornerOffset,
        left: cornerOffset,
        child: _buildCorner(
          rotateAngle: 0,
          length: cornerLength,
          thickness: cornerThickness,
        ),
      ),
      // Top right
      Positioned(
        top: cornerOffset,
        right: cornerOffset,
        child: _buildCorner(
          rotateAngle: 90,
          length: cornerLength,
          thickness: cornerThickness,
        ),
      ),
      // Bottom left
      Positioned(
        bottom: cornerOffset,
        left: cornerOffset,
        child: _buildCorner(
          rotateAngle: -90,
          length: cornerLength,
          thickness: cornerThickness,
        ),
      ),
      // Bottom right
      Positioned(
        bottom: cornerOffset,
        right: cornerOffset,
        child: _buildCorner(
          rotateAngle: 180,
          length: cornerLength,
          thickness: cornerThickness,
        ),
      ),
    ];
  }

  Widget _buildCorner({
    required double rotateAngle,
    required double length,
    required double thickness,
  }) {
    return Transform.rotate(
      angle: rotateAngle * 3.14159 / 180,
      child: SizedBox(
        width: length,
        height: length,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: length,
                height: thickness,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(thickness / 2),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: thickness,
                height: length,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(thickness / 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButtons(BuildContext context) {
    return Column(
      children: [
        // Main camera button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _captureImage(ImageSource.camera);
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Gallery button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _captureImage(ImageSource.gallery);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Choose from gallery',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Tips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Make sure the receipt is well-lit and flat',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return Container(
      color: AppColors.background.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Processing image...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Our AI is extracting subscription details',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Camera permission is required'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      String mimeType = 'image/jpeg';
      if (image.path.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (image.path.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (image.path.toLowerCase().endsWith('.heic')) {
        mimeType = 'image/heic';
      }

      if (mounted) {
        context.push(
          '/review',
          extra: {
            'imageData': base64Image,
            'filename': image.name,
            'mimeType': mimeType,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _CaptureBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Top gradient circle
    paint.shader = RadialGradient(
      colors: [
        AppColors.primary.withOpacity(0.08),
        AppColors.primary.withOpacity(0.0),
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.1),
      radius: size.width * 0.5,
    ));
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.1),
      size.width * 0.5,
      paint,
    );
    
    // Bottom gradient
    paint.shader = RadialGradient(
      colors: [
        AppColors.accent.withOpacity(0.06),
        AppColors.accent.withOpacity(0.0),
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.2, size.height * 0.9),
      radius: size.width * 0.6,
    ));
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.9),
      size.width * 0.6,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
