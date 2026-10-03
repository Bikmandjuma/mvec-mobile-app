import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api_client.dart';
import 'api_config.dart';
import 'theme.dart';

final _fmtMoney = NumberFormat('#,##0', 'en');

String money(num? value, {bool rwf = true}) {
  final v = (value ?? 0).round();
  return '${_fmtMoney.format(v)}${rwf ? ' RWF' : ''}';
}

String numFmt(num? value) => _fmtMoney.format(value ?? 0);

String shortDate(DateTime? d) => d == null ? '-' : DateFormat('dd MMM yyyy').format(d);

String shortDateTime(DateTime? d) => d == null ? '-' : DateFormat('dd MMM yyyy · HH:mm').format(d);

String initials(String name) {
  if (name.isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

String greeting(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

void showMvSnack(BuildContext context, String message, {bool success = false}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.info, color: success ? _mvSuccessGreen : null, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: success ? const Color(0xFF168D58) : null,
      ),
    );
}

const _mvSuccessGreen = Color(0xFF168D58);

/// Tries to extract a readable message from an error object.
String friendlyError(Object e) {
  // An ApiException already carries a human-readable message (including the
  // attempted base URL for connection failures) — surface it verbatim.
  if (e is ApiException) return e.message;

  final s = e.toString();
  final idx = s.indexOf('message":');
  if (idx != -1) {
    var m = s.substring(idx + 10);
    final end = m.indexOf('"');
    if (end != -1) m = m.substring(0, end);
    if (m.isNotEmpty) return m;
  }
  if (s.contains('SocketException') ||
      s.contains('Connection refused') ||
      s.contains('Connection timed out') ||
      s.contains('connection error')) {
    return 'Cannot reach $kApiBaseUrl. Start the backend and point the app at '
        'the right host (emulator: 10.0.2.2, real device: your LAN IP).';
  }
  return s.replaceAll('Exception: ', '').replaceAll('DioException [bad response]: ', 'Server error: ');
}

Color statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
    case 'VERIFIED':
    case 'PAID':
    case 'RELEASED':
    case 'SUCCESS':
    case 'COMPLETED':
    case 'DELIVERED':
    case 'PUBLISHED':
    case 'RESOLVED':
    case 'APPROVED':
    case 'OPEN':
      return MvColors.successText;
    case 'PENDING':
    case 'REVIEW':
    case 'UNDER_REVIEW':
    case 'WARNING':
    case 'HELD':
    case 'PROCESSING':
    case 'SHIPPED':
    case 'OUT_FOR_DELIVERY':
    case 'CONFIRMED':
    case 'DRAFT':
    case 'IN_PROGRESS':
    case 'INVESTIGATE':
    case 'MONITORING':
    case 'PAUSED':
      return MvColors.warningText;
    case 'BLOCK':
    case 'BLOCKED':
    case 'SUSPEND':
    case 'SUSPENDED':
    case 'FAILED':
    case 'CANCELLED':
    case 'REJECTED':
    case 'EXPIRED':
    case 'REFUNDED':
    case 'RETURNED':
    case 'HIGH':
    case 'CLOSED':
      return MvColors.errorText;
    default:
      return MvColors.neutralText;
  }
}

String titleCase(String s) {
  if (s.isEmpty) return s;
  return s.split(RegExp(r'[_\s]+')).map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
}

String formatDate(DateTime d) {
  final m = '${d.month}'.padLeft(2, '0');
  final day = '${d.day}'.padLeft(2, '0');
  return '$day/$m/${d.year}';
}