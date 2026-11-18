import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart' as vp;

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onComplete,
  });

  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _splashVideoAsset = 'assets/videos/splash.mp4';

  late AnimationController _slideController;
  late AnimationController _logoController;
  late AnimationController _xZoomInController;
  late AnimationController _xZoomOutController;
  late AnimationController _xFullScreenController;
  
  late Animation<double> _logoFade;
  late Animation<double> _xZoomIn;
  late Animation<double> _xZoomOut;
  late Animation<double> _xFullScreen;
  late Animation<double> _xRotation;

  vp.VideoPlayerController? _videoController;
  bool _isLoadingSplash = true;
  bool _isUsingVideoSplash = false;
  bool _hasCompleted = false;
  bool _fallbackAnimationStarted = false;
  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _xZoomInController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _xZoomOutController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _xFullScreenController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _xZoomIn = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _xZoomInController, curve: Curves.easeOut),
    );
    
    _xZoomOut = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(parent: _xZoomOutController, curve: Curves.easeIn),
    );
    
    _xFullScreen = Tween<double>(begin: 1.0, end: 8.0).animate(
      CurvedAnimation(parent: _xFullScreenController, curve: Curves.easeInOut),
    );
    
    _xRotation = Tween<double>(begin: 0.0, end: 6.28).animate(
      CurvedAnimation(parent: _xZoomInController, curve: Curves.easeInOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    final videoLoaded = await _tryStartVideoSplash();
    if (!mounted || _hasCompleted) return;

    if (!videoLoaded) {
      _startFallbackAnimation();
    }
  }

  Future<bool> _tryStartVideoSplash() async {
    try {
      await rootBundle.load(_splashVideoAsset);
    } catch (_) {
      return false;
    }

    final controller = vp.VideoPlayerController.asset(_splashVideoAsset);

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return true;
      }

      await controller.setLooping(false);
      await controller.setVolume(0);
      controller.addListener(_handleVideoProgress);

      setState(() {
        _videoController = controller;
        _isLoadingSplash = false;
        _isUsingVideoSplash = true;
      });

      await controller.play();
      return true;
    } catch (_) {
      controller.removeListener(_handleVideoProgress);
      await controller.dispose();
      return false;
    }
  }

  void _handleVideoProgress() {
    final controller = _videoController;
    if (controller == null || _hasCompleted) return;

    final value = controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) return;

    final isComplete = value.position >= value.duration;
    if (isComplete) {
      _completeSplash();
    }
  }

  Future<void> _startFallbackAnimation() async {
    if (_fallbackAnimationStarted || _hasCompleted) return;
    _fallbackAnimationStarted = true;
    _isLoadingSplash = false;

    // Show logo
    setState(() => _currentSlide = 0);
    await _logoController.forward();
    if (!mounted || _hasCompleted) return;
    await Future.delayed(const Duration(milliseconds: 1500));

    // Slide to X
    if (!mounted || _hasCompleted) return;
    setState(() => _currentSlide = 1);
    await _slideController.forward();

    // X zoom in with rotation
    await _xZoomInController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // X zoom out
    await _xZoomOutController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // X full screen zoom
    await _xFullScreenController.forward();

    _completeSplash();
  }

  void _completeSplash() {
    if (_hasCompleted) return;
    _hasCompleted = true;

    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    // Ensure system bars/insets are restored even if splash is removed early.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _videoController?.removeListener(_handleVideoProgress);
    _videoController?.dispose();
    _slideController.dispose();
    _logoController.dispose();
    _xZoomInController.dispose();
    _xZoomOutController.dispose();
    _xFullScreenController.dispose();
    super.dispose();
  }

  Widget _buildLogoSlide() {
    return Center(
      child: AnimatedBuilder(
        animation: _logoController,
        builder: (context, child) {
          return Opacity(
            opacity: _logoFade.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 320,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 6),
                const Text(
                  'The Ultimate Property Resource...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildXSlide() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_xZoomInController, _xZoomOutController, _xFullScreenController]),
        builder: (context, child) {
          double scale;
          
          if (_xFullScreenController.isAnimating || _xFullScreenController.isCompleted) {
            scale = _xFullScreen.value;
          } else if (_xZoomInController.isCompleted) {
            scale = _xZoomOut.value;
          } else {
            scale = _xZoomIn.value;
          }
              
          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: _xRotation.value,
              child: Image.asset(
                'assets/images/x_logo.png',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/logo.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoSplash() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return _buildLoadingSplash();
    }

    final size = controller.value.size;
    final videoWidth = size.width > 0 ? size.width : 16.0;
    final videoHeight = size.height > 0 ? size.height : 9.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFF7F8FA)),
        Center(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: vp.VideoPlayer(controller),
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x33000000),
                Color(0x11000000),
                Color(0xAA000000),
              ],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 96,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                'The Ultimate Property Resource...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      blurRadius: 12,
                      color: Colors.black54,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSplash() {
    return Container(
      color: const Color(0xFFF7F8FA),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 18),
          const CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: _isLoadingSplash
              ? _buildLoadingSplash()
              : _isUsingVideoSplash
              ? KeyedSubtree(
                  key: const ValueKey('video-splash'),
                  child: _buildVideoSplash(),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  child: _currentSlide == 0
                      ? KeyedSubtree(
                          key: const ValueKey('logo-slide'),
                          child: _buildLogoSlide(),
                        )
                      : KeyedSubtree(
                          key: const ValueKey('x-slide'),
                          child: _buildXSlide(),
                        ),
                ),
        ),
      ),
    );
  }
}
