import 'package:flutter/foundation.dart';

/// Pārlūkā (Flutter Web) attēli tiek zīmēti uz WebGL CanvasKit kanvas,
/// kas pieprasa CORS 'Access-Control-Allow-Origin' galveni.
/// Hetzner S3 jau atbalsta CORS, bet ārējiem portāliem (piem., pašvaldību lapām,
/// kuras vēl nav paspēts nosinhronizēt ar S3) izmantojam drošu Cloudflare proxy,
/// lai pārlūkā nerastos "CORS error".
///
/// Uz mobilajām ierīcēm (Android, iOS) un Desktop nekas netiek mainīts.
String? webSafeImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (!kIsWeb) return url;

  final uri = Uri.tryParse(url);
  if (uri == null) return url;

  // Ja attēls jau ir uz mūsu Hetzner S3 vai vietējā domēna, CORS darbojas tieši
  if (uri.host.contains('your-objectstorage.com') ||
      uri.host.contains('piedzivo.lv') ||
      uri.host.contains('localhost')) {
    return url;
  }

  // Ārējiem trešo pušu resursiem izmantojam Cloudflare CDN attēlu proxy ar CORS atbalstu
  return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}';
}

