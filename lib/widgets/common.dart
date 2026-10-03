import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import 'mv_icon.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.overrideColor});
  final String? status;
  final Color? overrideColor;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      status ?? 'UNKNOWN';

  @override
  Widget build(BuildContext context) {
    final s = (status ?? 'UNKNOWN').toUpperCase();
    final fg = overrideColor ?? statusColor(s);
    Color bg;
    if (overrideColor != null) {
      bg = overrideColor!.withValues(alpha: .14);
    } else if (fg == MvColors.successText) {
      bg = MvColors.successBg;
    } else if (fg == MvColors.warningText) {
      bg = MvColors.warningBg;
    } else if (fg == MvColors.errorText) {
      bg = MvColors.errorBg;
    } else {
      bg = MvColors.neutralBg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        titleCase(s),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaColor,
    this.icon = 'chart',
    this.onTap,
  });

  final String label;
  final String value;
  final String? delta;

  /// Colour of the [delta] line. Defaults to the success green, which is wrong
  /// for a negative movement — pass [MvColors.errorText] for those.
  final Color? deltaColor;

  final String icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: .65) ??
        MvColors.muted;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: MvColors.metricIconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: MvIcon(icon, size: 20, color: MvColors.primaryDeep),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFontsManrope.metricValue,
                    ),
                    if (delta != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        delta!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: deltaColor ?? MvColors.successText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small helper so metric values use Manrope 800 20px like the frontend.
class GoogleFontsManrope {
  static TextStyle get metricValue => GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -.2,
  );
}

class PageHead extends StatelessWidget {
  const PageHead({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(), style: context.mvEyebrow),
              const SizedBox(height: 7),
              Text(title, style: context.mvH1),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ],
          );
          final actionRow = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: actions,
          );

          if (constraints.maxWidth <= 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  actionRow,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: heading),
              const SizedBox(width: 20),
              actionRow,
            ],
          );
        },
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.danger = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final bool expanded;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          MvIcon(icon!, size: 15, color: Colors.white),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
    final btn = Material(
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        decoration: BoxDecoration(
          gradient: danger ? null : MvColors.gradient,
          color: danger ? MvColors.dangerBtn : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
            child: expanded ? Center(child: child) : child,
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class OutlineMvButton extends StatelessWidget {
  const OutlineMvButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? MvIcon(icon!, size: 15) : const SizedBox.shrink(),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class InfoBox extends StatelessWidget {
  const InfoBox(this.text, {super.key, this.icon = 'shield'});
  final String text;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MvColors.infoBoxBg,
        border: Border.all(color: MvColors.infoBoxBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          MvIcon(icon, size: 18, color: MvColors.primaryDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: MvColors.infoBoxText,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataCard extends StatelessWidget {
  const DataCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget? header;
            if (title != null) {
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ],
              );

              if (trailing == null) {
                header = titleBlock;
              } else if (constraints.maxWidth <= 420) {
                header = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleBlock,
                    Align(alignment: Alignment.centerRight, child: trailing),
                  ],
                );
              } else {
                header = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(child: titleBlock), trailing!],
                );
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (header != null) ...[header, const SizedBox(height: 14)],
                child,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Modal bottom sheet mirroring the frontend `.modal` detail view.
Future<void> showMvDetailModal(
  BuildContext context, {
  required String title,
  required List<Widget> children,
  Widget? footer,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (ctx) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * .85,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              footer ??
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: 'Done',
                      onPressed: () => Navigator.pop(ctx),
                      expanded: true,
                    ),
                  ),
            ],
          ),
        ),
  );
}

class KeyValueGrid extends StatelessWidget {
  const KeyValueGrid({super.key, required this.entries});
  final List<MapEntry<String, String>> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children:
          entries
              .map(
                (e) => SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .6,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.message = 'No records found'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(strokeWidth: 2.5),
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MvIcon('bell', size: 28, color: MvColors.dangerIcon),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: MvColors.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> copyToClipboard(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) {
    showMvSnack(context, 'Copied to clipboard', success: true);
  }
}
