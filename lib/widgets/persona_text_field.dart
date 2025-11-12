import 'package:flutter/material.dart';

class PersonaTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? suffixIcon;

  const PersonaTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onTap,
    this.enabled = true,
    this.suffixIcon,
  });

  @override
  State<PersonaTextField> createState() => _PersonaTextFieldState();
}

class _PersonaTextFieldState extends State<PersonaTextField>
    with TickerProviderStateMixin {
  late AnimationController _focusController;
  late AnimationController _typingController;
  late Animation<double> _focusAnimation;
  late Animation<double> _typingAnimation;
  late Animation<Color?> _colorAnimation;
  late FocusNode _focusNode;

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    _focusController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _typingController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );

    _focusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeInOutCubic),
    );

    _typingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );

    _colorAnimation =
        ColorTween(
          begin: Colors.grey[400],
          end: Theme.of(context).colorScheme.primary,
        ).animate(
          CurvedAnimation(
            parent: _focusController,
            curve: Curves.easeInOutCubic,
          ),
        );

    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _focusController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller.text.isNotEmpty && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
      _typingController.forward().then((_) {
        _typingController.reverse().then((_) {
          setState(() {
            _isTyping = false;
          });
        });
      });
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_focusAnimation, _typingAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _typingAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _colorAnimation.value!.withOpacity(
                    0.1 * _focusAnimation.value,
                  ),
                  blurRadius: 8 * _focusAnimation.value,
                  spreadRadius: 2 * _focusAnimation.value,
                  offset: Offset(0, 4 * _focusAnimation.value),
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              validator: widget.validator,
              onTap: widget.onTap,
              enabled: widget.enabled,
              onChanged: (value) {
                // Trigger typing animation
                if (value.isNotEmpty && !_isTyping) {
                  setState(() {
                    _isTyping = true;
                  });
                  _typingController.forward().then((_) {
                    _typingController.reverse().then((_) {
                      setState(() {
                        _isTyping = false;
                      });
                    });
                  });
                }
              },
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                prefixIcon: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  child: Icon(
                    widget.prefixIcon,
                    color: _colorAnimation.value,
                    size: 20 + (2 * _focusAnimation.value),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _colorAnimation.value!,
                    width: 1 + (1 * _focusAnimation.value),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: widget.suffixIcon,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget para animación de texto escribiendo estilo Persona
class PersonaTypingAnimation extends StatefulWidget {
  final String text;
  final Duration duration;
  final TextStyle? style;
  final TextAlign textAlign;

  const PersonaTypingAnimation({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 2000),
    this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  State<PersonaTypingAnimation> createState() => _PersonaTypingAnimationState();
}

class _PersonaTypingAnimationState extends State<PersonaTypingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _animation.addListener(() {
      final progress = _animation.value;
      final textLength = widget.text.length;
      final currentLength = (progress * textLength).round();

      setState(() {
        _displayText = widget.text.substring(0, currentLength);
      });
    });

    _controller.forward();
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
        return Text(
          _displayText,
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}
