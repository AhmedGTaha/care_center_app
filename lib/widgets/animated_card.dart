import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  
  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
  });
  
  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: widget.margin ?? const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: AppTheme.borderRadiusMedium,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: _elevationAnimation.value * 2,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppTheme.borderRadiusMedium,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      child: Padding(
                        padding: widget.padding ?? const EdgeInsets.all(15),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isLarge;
  
  const StatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isLarge ? 16 : 12,
                vertical: isLarge ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: config['color'].withOpacity(0.15),
                borderRadius: AppTheme.borderRadiusSmall,
                border: Border.all(
                  color: config['color'],
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    config['icon'],
                    size: isLarge ? 18 : 14,
                    color: config['color'],
                  ),
                  SizedBox(width: isLarge ? 8 : 6),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: isLarge ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: config['color'],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return {
          'color': AppTheme.availableColor,
          'icon': Icons.check_circle,
        };
      case 'rented':
        return {
          'color': AppTheme.rentedColor,
          'icon': Icons.shopping_cart,
        };
      case 'donated':
        return {
          'color': AppTheme.donatedColor,
          'icon': Icons.volunteer_activism,
        };
      case 'maintenance':
        return {
          'color': AppTheme.maintenanceColor,
          'icon': Icons.build,
        };
      case 'pending':
        return {
          'color': AppTheme.warningColor,
          'icon': Icons.pending,
        };
      case 'approved':
        return {
          'color': AppTheme.successColor,
          'icon': Icons.check_circle,
        };
      case 'rejected':
        return {
          'color': AppTheme.errorColor,
          'icon': Icons.cancel,
        };
      default:
        return {
          'color': AppTheme.textLight,
          'icon': Icons.info,
        };
    }
  }
}

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });
  
  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppTheme.borderRadiusMedium,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade200,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? textStyle;
  final Duration duration;
  
  const AnimatedCounter({
    super.key,
    required this.value,
    this.textStyle,
    this.duration = const Duration(milliseconds: 500),
  });
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          value.toString(),
          style: textStyle ?? AppTheme.headingMedium,
        );
      },
    );
  }
}

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient gradient;
  
  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.gradient = AppTheme.primaryGradient,
  });
  
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  
  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.height = 8,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.textLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
        builder: (context, value, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color ?? AppTheme.primaryColor,
                    (color ?? AppTheme.primaryColor).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: (color ?? AppTheme.primaryColor).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SlideInAnimation extends StatelessWidget {
  final Widget child;
  final int delay;
  final Offset beginOffset;
  
  const SlideInAnimation({
    super.key,
    required this.child,
    this.delay = 0,
    this.beginOffset = const Offset(0, 0.3),
  });
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            beginOffset.dx * (1 - value) * 100,
            beginOffset.dy * (1 - value) * 100,
          ),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}