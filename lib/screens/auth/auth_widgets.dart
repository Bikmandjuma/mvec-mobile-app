import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/common.dart';

/// Branded shell for the MVEC auth screens: gradient backdrop + card,
/// mirroring the frontend `AuthLayout` styling.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    this.children = const [],
    this.footer,
    this.topBar,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;
  final Widget? topBar;

  /// Renders a more compact card (used by the reset-password sub-screens).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: MvColors.gradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(28, compact ? 24 : 30, 28, 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .18),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (topBar != null) ...[
                        topBar!,
                        const SizedBox(height: 8),
                      ],
                      const _LogoLockup(),
                      const SizedBox(height: 22),
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ...children,
                      if (footer != null) ...[
                        const SizedBox(height: 18),
                        footer!,
                      ],
                    ],
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

class _LogoLockup extends StatelessWidget {
  const _LogoLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            'MVEC',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              foreground: Paint()
                ..shader = MvColors.gradient.createShader(
                  const Rect.fromLTWH(0, 0, 120, 40),
                ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Center(
          child: Text(
            'SHOP · SELL · GROW',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w900,
              color: MvColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Error banner used on auth forms.
class AuthBanner extends StatelessWidget {
  const AuthBanner.error(this.text, {super.key}) : _success = false;
  const AuthBanner.success(this.text, {super.key}) : _success = true;

  final String text;
  final bool _success;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _success ? MvColors.successBg : MvColors.errorBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _success ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: _success ? MvColors.successText : MvColors.errorText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: _success ? MvColors.successText : MvColors.errorText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard labelled auth input with a leading icon.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.icon = Icons.edit_outlined,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.suffix,
    this.enabled = true,
    this.onSubmitted,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 0),
        suffixIcon: suffix,
      ),
    );
  }
}

/// Row of six single-digit boxes for the reset verification code.
class OtpField extends StatefulWidget {
  const OtpField({super.key, this.onChanged, this.enabled = true});

  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<OtpField> createState() => OtpFieldState();
}

class OtpFieldState extends State<OtpField> {
  static const _length = 6;
  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _nodes = List.generate(_length, (_) => FocusNode());

  String get code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _notify();
    if (widget.enabled) _nodes.first.requestFocus();
  }

  void _notify() => widget.onChanged?.call(code);

  void _handleChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      // Pasted multi-digit value: distribute across the remaining boxes.
      var i = index;
      for (var k = 0; k < digits.length && i < _length; k++, i++) {
        _controllers[i].value = TextEditingValue(
          text: digits[k],
          selection: TextSelection.collapsed(offset: 1),
        );
      }
      final lastFilled = i - 1;
      if (lastFilled < _length - 1) {
        _nodes[lastFilled + 1].requestFocus();
      } else {
        _nodes.last.requestFocus();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    } else if (digits.isEmpty) {
      _controllers[index].clear();
    } else {
      _controllers[index].value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: 1),
      );
      if (index < _length - 1) {
        _nodes[index + 1].requestFocus();
      } else {
        _nodes.last.requestFocus();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    }
    _notify();
  }

  KeyEventResult _handleKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey.keyLabel == 'Backspace' &&
        index > 0 &&
        _controllers[index].text.isEmpty) {
      _nodes[index - 1].requestFocus();
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_length, (index) {
        return SizedBox(
          width: 46,
          height: 52,
          child: Focus(
            onKeyEvent: (node, event) => _handleKey(index, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _nodes[index],
              enabled: widget.enabled,
              autofocus: index == 0,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                counterText: '',
                hintText: '·',
                hintStyle: TextStyle(
                  fontSize: 22,
                  color: Theme.of(context).disabledColor,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => _handleChanged(index, v),
            ),
          ),
        );
      }),
    );
  }
}

/// Three-step progress indicator for the password reset flow.
class ResetStepIndicator extends StatelessWidget {
  const ResetStepIndicator({super.key, required this.current});

  /// 1 = email, 2 = verification code, 3 = new password.
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['Email', 'Code', 'Password'];
    return Row(
      children: List.generate(labels.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: (index ~/ 2) + 1 < current
                  ? MvColors.primary
                  : Theme.of(context).dividerColor,
            ),
          );
        }
        final step = index ~/ 2 + 1;
        final active = step <= current;
        final done = step < current;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? MvColors.primaryDeep : MvColors.neutralBg,
                border: active
                    ? null
                    : Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$step',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: active ? Colors.white : MvColors.muted,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[step - 1],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: active ? MvColors.primaryDeep : MvColors.muted,
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Convenience wrapper so screens can show the branded submit button.
Widget authSubmitButton(BuildContext context, {
  required String label,
  bool? enabled,
  VoidCallback? onPressed,
  bool expanded = true,
}) {
  return GradientButton(
    label: label,
    onPressed: (enabled ?? true) ? onPressed : null,
    expanded: expanded,
    icon: 'arrow',
  );
}

/// Convenience: a "Don't have/have an account?" style footer line.
Widget authLinkFooter(BuildContext context, String prefix, String linkText, VoidCallback onTap) {
  return Column(
    children: [
      Text(
        prefix,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: Theme.of(context).hintColor),
      ),
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
        child: Text(linkText, style: const TextStyle(fontSize: 12.5)),
      ),
    ],
  );
}

void showAuthSnack(BuildContext context, String message, {bool success = false}) =>
    showMvSnack(context, message, success: success);