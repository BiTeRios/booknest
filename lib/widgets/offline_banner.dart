import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/format.dart';
import '../models/offline_status.dart';

/// Полоса над панелью вкладок: «нет связи — показаны сохранённые данные».
/// Видна, пока хотя бы один список пришёл из offline-кэша.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<OfflineStatus>();
    final scheme = Theme.of(context).colorScheme;
    final at = status.cachedAt;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: at == null
          ? const SizedBox(width: double.infinity)
          : Material(
              color: scheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      color: scheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Нет связи с сервером. Показаны данные '
                        'от ${formatDate(at)} ${formatTime(at)}',
                        style: TextStyle(color: scheme.onTertiaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
