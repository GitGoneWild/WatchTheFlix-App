// AccountOverviewCard
// Reusable component displaying Xtream account information.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../xtreamcodes/account/xtream_account_models.dart';

/// Account overview card widget
class AccountOverviewCard extends StatelessWidget {
  final XtreamAccountOverview accountInfo;
  final String profileName;
  final VoidCallback? onRefresh;
  final VoidCallback? onCopyM3uUrl;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  const AccountOverviewCard({
    super.key,
    required this.accountInfo,
    required this.profileName,
    this.onRefresh,
    this.onCopyM3uUrl,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _buildErrorCard(context);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          _buildBody(context),
          const Divider(height: 1),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load account',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final status = accountInfo.userInfo.accountStatus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  accountInfo.userInfo.username,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _buildStatusPill(context, status),
        ],
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, AccountStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case AccountStatus.active:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        break;
      case AccountStatus.trial:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        break;
      case AccountStatus.expired:
      case AccountStatus.disabled:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildUserInfoSection(context)),
          const SizedBox(width: 16),
          Expanded(child: _buildServerInfoSection(context)),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    final userInfo = accountInfo.userInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'User Details', Icons.person_outline),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Connections',
          '${userInfo.activeConnections} / ${userInfo.maxConnections}',
          Icons.devices,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          'Expires',
          _formatExpiry(userInfo),
          Icons.calendar_today,
          valueColor: _getExpiryColor(userInfo),
        ),
        if (userInfo.createdAt != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Created',
            _formatDate(userInfo.createdAt!),
            Icons.access_time,
          ),
        ],
        if (userInfo.message.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              userInfo.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServerInfoSection(BuildContext context) {
    final serverInfo = accountInfo.serverInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Server Details', Icons.dns_outlined),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          'Server',
          serverInfo.url,
          Icons.link,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          'Protocol',
          serverInfo.serverProtocol.toUpperCase(),
          Icons.security,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          'Ports',
          'HTTP: ${serverInfo.port}, HTTPS: ${serverInfo.httpsPort}',
          Icons.settings_ethernet,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          'Timezone',
          serverInfo.timezone,
          Icons.schedule,
        ),
        if (serverInfo.timeNow.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Server Time',
            serverInfo.timeNow,
            Icons.access_time_filled,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: valueColor,
                      fontWeight: valueColor != null ? FontWeight.bold : null,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final formats = accountInfo.userInfo.allowedOutputFormats;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Output format chips
          if (formats.isNotEmpty) ...[
            const Icon(Icons.videocam_outlined, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: formats.map((format) {
                  return Chip(
                    label: Text(
                      format.toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
          ],
          const Spacer(),
          // Actions
          if (onCopyM3uUrl != null)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy M3U URL',
              onPressed: () {
                onCopyM3uUrl!();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('M3U URL copied to clipboard')),
                );
              },
            ),
          if (onRefresh != null)
            isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: onRefresh,
                  ),
        ],
      ),
    );
  }

  String _formatExpiry(XtreamUserInfo userInfo) {
    if (userInfo.expDate == null) return 'N/A';

    final daysUntil = userInfo.daysUntilExpiry;
    final dateStr = _formatDate(userInfo.expDate!);

    if (daysUntil == null) return dateStr;
    if (daysUntil < 0) return 'Expired ${-daysUntil} days ago';
    if (daysUntil == 0) return 'Expires today';
    if (daysUntil == 1) return 'Expires tomorrow';
    return 'In $daysUntil days ($dateStr)';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color? _getExpiryColor(XtreamUserInfo userInfo) {
    final daysUntil = userInfo.daysUntilExpiry;
    if (daysUntil == null) return null;
    if (daysUntil < 0) return Colors.red;
    if (daysUntil <= 7) return Colors.orange;
    if (daysUntil <= 30) return Colors.amber;
    return Colors.green;
  }
}

/// Loading state for account overview
class AccountOverviewCardLoading extends StatelessWidget {
  const AccountOverviewCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
