import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/phivolcs_event.dart';
import '../services/quake_data_service.dart';

class FactsHomeScreen extends StatelessWidget {
  final VoidCallback onOpenMap;
  final VoidCallback onToggleThemeMode;
  final QuakeDataService _dataService = QuakeDataService();

  FactsHomeScreen({
    super.key,
    required this.onOpenMap,
    required this.onToggleThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF6F6F6);
    final card = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF121212);
    final sub = isDark ? Colors.white70 : const Color(0xFF4F4F4F);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFC4C02), Color(0xFFD94300)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QuakeNav',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fast evacuation guidance when an earthquake hits.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: onOpenMap,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFFC4C02),
                          ),
                          child: const Text('Open Map'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: onToggleThemeMode,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          child: const Text('Theme'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PHIVOLCS Feed (Info Only)',
                style: TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<PhivolcsEvent?>(
                stream: _dataService.phivolcsLatestStream(),
                builder: (context, latestSnap) {
                  final latest = latestSnap.data;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: latest == null
                        ? Text(
                            'No PHIVOLCS data yet.',
                            style: TextStyle(color: sub, fontSize: 13),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Latest bulletin',
                                style: TextStyle(
                                  color: text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mag ${latest.magnitude?.toStringAsFixed(1) ?? "-"} • Depth ${latest.depthKm?.toStringAsFixed(0) ?? "-"} km',
                                style: TextStyle(
                                  color: text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                latest.locationText.isEmpty
                                    ? 'Location unavailable'
                                    : latest.locationText,
                                style: TextStyle(color: sub, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                latest.dateTimePH.isEmpty
                                    ? 'Time unavailable'
                                    : latest.dateTimePH,
                                style: TextStyle(color: sub, fontSize: 12),
                              ),
                            ],
                          ),
                  );
                },
              ),
              StreamBuilder<List<PhivolcsEvent>>(
                stream: _dataService.phivolcsEventsStream(limit: 8),
                builder: (context, eventsSnap) {
                  final events = eventsSnap.data ?? const <PhivolcsEvent>[];
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent PHIVOLCS logs',
                          style: TextStyle(
                            color: text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (events.isEmpty)
                          Text(
                            'No logs yet.',
                            style: TextStyle(color: sub, fontSize: 13),
                          )
                        else
                          ...events.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF242424)
                                      : const Color(0xFFF1F2F4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'M${e.magnitude?.toStringAsFixed(1) ?? "-"} • ${e.dateTimePH}',
                                      style: TextStyle(
                                        color: text,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      e.locationText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: sub, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Earthquake Facts',
                style: TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _FactCard(
                color: card,
                title: 'Drop, Cover, Hold',
                body:
                    'During shaking, drop to the ground, cover your head/neck, and hold on until shaking stops.',
                textColor: text,
                subTextColor: sub,
              ),
              _FactCard(
                color: card,
                title: 'Most injuries are preventable',
                body:
                    'Falling objects and broken glass cause many injuries. Stay away from windows and shelves.',
                textColor: text,
                subTextColor: sub,
              ),
              _FactCard(
                color: card,
                title: 'Expect aftershocks',
                body:
                    'After the main quake, smaller aftershocks can follow. Keep monitoring alerts and stay cautious.',
                textColor: text,
                subTextColor: sub,
              ),
              _FactCard(
                color: card,
                title: 'Know your exit route',
                body:
                    'Your assigned building route can reduce crowding and speed up evacuation during emergencies.',
                textColor: text,
                subTextColor: sub,
              ),
              const SizedBox(height: 8),
              Text(
                'Articles & Journals',
                style: TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _ArticleCoverCard(
                title: 'PHIVOLCS Earthquake Preparedness',
                source: 'PHIVOLCS',
                imageUrl:
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/USGS_seismograph.jpg/1280px-USGS_seismograph.jpg',
                articleUrl:
                    'https://phivolcs.dost.gov.ph/index.php/earthquake/earthquake-preparedness',
              ),
              _ArticleCoverCard(
                title: 'USGS Earthquake Hazards Program',
                source: 'USGS',
                imageUrl:
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Earthquake_damage.jpg/1280px-Earthquake_damage.jpg',
                articleUrl: 'https://www.usgs.gov/programs/earthquake-hazards',
              ),
              _ArticleCoverCard(
                title: 'WHO: Earthquakes and health response',
                source: 'WHO',
                imageUrl:
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/2015_Nepal_earthquake_-_Kathmandu.jpg/1280px-2015_Nepal_earthquake_-_Kathmandu.jpg',
                articleUrl:
                    'https://www.who.int/emergencies/disease-outbreak-news',
              ),
              const SizedBox(height: 8),
              Text(
                'Recent News (Headlines)',
                style: TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _ArticleCoverCard(
                title: 'Recent earthquakes and official advisories',
                source: 'Google News',
                imageUrl:
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/USGS_Shakemap.jpg/1280px-USGS_Shakemap.jpg',
                articleUrl:
                    'https://news.google.com/search?q=earthquake%20when%3A7d&hl=en-US&gl=US&ceid=US%3Aen',
              ),
              _ArticleCoverCard(
                title: 'Earthquake latest updates in the Philippines',
                source: 'Google News',
                imageUrl:
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Collapsed_building_after_earthquake.jpg/1280px-Collapsed_building_after_earthquake.jpg',
                articleUrl:
                    'https://news.google.com/search?q=earthquake%20Philippines%20when%3A7d&hl=en-US&gl=US&ceid=US%3Aen',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  final Color color;
  final Color textColor;
  final Color subTextColor;
  final String title;
  final String body;

  const _FactCard({
    required this.color,
    required this.textColor,
    required this.subTextColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCoverCard extends StatelessWidget {
  final String title;
  final String source;
  final String imageUrl;
  final String articleUrl;

  const _ArticleCoverCard({
    required this.title,
    required this.source,
    required this.imageUrl,
    required this.articleUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final uri = Uri.parse(articleUrl);
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open article')),
          );
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: FutureBuilder<String?>(
                future: _ArticleImageResolver.resolve(articleUrl),
                builder: (context, snapshot) {
                  final resolvedUrl = snapshot.data ?? imageUrl;
                  return Image.network(
                    resolvedUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFFC4C02).withValues(alpha: 0.2),
                      alignment: Alignment.center,
                      child: const Icon(Icons.article_outlined),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF666666),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF111111),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleImageResolver {
  static final Map<String, Future<String?>> _cache = {};

  static Future<String?> resolve(String articleUrl) {
    return _cache.putIfAbsent(articleUrl, () => _fetch(articleUrl));
  }

  static Future<String?> _fetch(String articleUrl) async {
    try {
      final response = await http.get(Uri.parse(articleUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final html = response.body;
      return _extractMetaImage(html, articleUrl);
    } catch (_) {
      return null;
    }
  }

  static String? _extractMetaImage(String html, String articleUrl) {
    final og = RegExp(
      '<meta[^>]+property=["\\\']og:image["\\\'][^>]+content=["\\\']([^"\\\']+)["\\\']',
      caseSensitive: false,
    ).firstMatch(html);
    if (og != null) {
      return _normalizeUrl(og.group(1), articleUrl);
    }

    final twitter = RegExp(
      '<meta[^>]+name=["\\\']twitter:image(?::src)?["\\\'][^>]+content=["\\\']([^"\\\']+)["\\\']',
      caseSensitive: false,
    ).firstMatch(html);
    if (twitter != null) {
      return _normalizeUrl(twitter.group(1), articleUrl);
    }

    final firstImage = RegExp(
      '<img[^>]+src=["\\\']([^"\\\']+)["\\\']',
      caseSensitive: false,
    ).firstMatch(html);
    if (firstImage != null) {
      return _normalizeUrl(firstImage.group(1), articleUrl);
    }

    return null;
  }

  static String? _normalizeUrl(String? value, String articleUrl) {
    if (value == null || value.isEmpty) return null;
    final clean = value.replaceAll('&amp;', '&').trim();
    final uri = Uri.tryParse(clean);
    if (uri == null) {
      return null;
    }
    if (uri.hasScheme) {
      return clean;
    }
    final base = Uri.tryParse(articleUrl);
    if (base == null) {
      return clean;
    }
    return base.resolveUri(uri).toString();
  }
}
