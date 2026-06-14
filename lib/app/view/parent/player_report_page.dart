import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/model/player_css_snapshot_model.dart';
import 'package:jsba_app/app/model/player_rating_model.dart';
import 'package:jsba_app/app/model/metric_definition_model.dart';
import 'package:jsba_app/app/service/metric_definition_service.dart';
import 'package:jsba_app/app/viewmodel/assessment_view_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';

@RoutePage()
class PlayerReportPage extends StatefulWidget {
  final String playerId;

  const PlayerReportPage({super.key, required this.playerId});

  @override
  State<PlayerReportPage> createState() => _PlayerReportPageState();
}

class _PlayerReportPageState extends State<PlayerReportPage> {
  final _metricService = MetricDefinitionService();
  late Future<List<MetricDefinitionModel>> _metricDefinitionsFuture;

  @override
  void initState() {
    super.initState();
    _metricDefinitionsFuture = _metricService.getAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.currentUser != null) {
        context.read<ParentViewModel>().loadMyKids(authVM.currentUser!.uid);
      }
      context.read<AssessmentViewModel>().loadPlayerData(widget.playerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final parentVM = context.watch<ParentViewModel>();
    final assessmentVM = context.watch<AssessmentViewModel>();

    final allPlayers = [
      if (parentVM.selfPlayer != null) parentVM.selfPlayer!,
      ...parentVM.allKids,
    ];

    final player = allPlayers.where((p) => p.id == widget.playerId).firstOrNull;

    if (parentVM.isLoading) {
      return Scaffold(
        appBar: const AppBarTitle(
          title: 'Player Report',
          blackBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (player == null) {
      return Scaffold(
        appBar: const AppBarTitle(
          title: 'Player Report',
          blackBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Player not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.router.back(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final isSelf = player.isSelf;

    return Scaffold(
      appBar: AppBarTitle(
        title: isSelf ? 'My Report' : '${player.name} Report',
        blackBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<MetricDefinitionModel>>(
          future: _metricDefinitionsFuture,
          builder: (context, snapshot) {
            final metricDefinitions = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlayerHeader(player, isSelf),
                const SizedBox(height: 24),
                _buildPlayerInfoSection(player),
                const SizedBox(height: 24),
                _buildPlayerReportSection(assessmentVM),
                const SizedBox(height: 24),
                _buildPlayerProgressSection(assessmentVM, metricDefinitions),
                const SizedBox(height: 24),
                _buildAiSummarySection(parentVM),
                const SizedBox(height: 24),
                if (!isSelf && player.status == PlayerStatus.pending)
                  _buildPendingNotice(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerHeader(PlayerModel player, bool isSelf) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage:
                  player.imageUrl != null && player.imageUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(player.imageUrl!)
                  : null,
              child: (player.imageUrl == null || player.imageUrl!.isEmpty)
                  ? Icon(
                      isSelf ? Icons.person : Icons.child_care,
                      size: 40,
                      color: AppTheme.primaryColor,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSelf ? 'My Profile' : 'My Kid',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoSection(PlayerModel player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Info',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(Icons.person, 'Name', player.name),
                _buildDetailRow(
                  Icons.cake,
                  'Age',
                  '${player.computedAge} years old',
                ),
                _buildDetailRow(Icons.trending_up, 'Level', player.level),
                _buildDetailRow(
                  Icons.phone,
                  'Phone',
                  player.phone.isNotEmpty ? player.phone : 'Not provided',
                ),
                if (player.parentName != null)
                  _buildDetailRow(
                    Icons.supervisor_account,
                    'Guardian',
                    player.parentName!,
                  ),
                if (player.parentPhone != null &&
                    player.parentPhone!.isNotEmpty)
                  _buildDetailRow(
                    Icons.phone_android,
                    'Guardian Phone',
                    player.parentPhone!,
                  ),
                if (player.parentEmail != null &&
                    player.parentEmail!.isNotEmpty)
                  _buildDetailRow(
                    Icons.email,
                    'Guardian Email',
                    player.parentEmail!,
                  ),
                _buildDetailRow(
                  Icons.verified,
                  'Status',
                  player.status == PlayerStatus.approved
                      ? 'Approved'
                      : 'Pending Approval',
                  valueColor: player.status == PlayerStatus.approved
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerReportSection(AssessmentViewModel vm) {
    final css = vm.latestCss;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Report',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (vm.isLoadingPlayer && css == null)
          const _ReportCard(child: Center(child: CircularProgressIndicator()))
        else if (css == null)
          const _EmptyAssessmentCard(
            icon: Icons.description_outlined,
            title: 'No assessment report yet',
            subtitle:
                'Reports appear after a physical, skill, or competition event.',
          )
        else
          _ReportCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _scoreOutOfTen(css.cssTotal),
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Text(
                            'Composite Skill Score',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    _TrendBadge(trend: css.trend),
                  ],
                ),
                const SizedBox(height: 20),
                _ScoreBar(label: 'Physical', score: css.physicalScore),
                _ScoreBar(label: 'Technical', score: css.technicalScore),
                _ScoreBar(label: 'Match', score: css.matchScore),
                if (css.hasStaleComponent) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Some scores are more than 60 days old.',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerProgressSection(
    AssessmentViewModel vm,
    List<MetricDefinitionModel> metricDefinitions,
  ) {
    final rating = vm.playerRating;
    final physical = vm.latestPhysical;
    final skill = vm.latestSkill;
    final recentMatches = vm.matchResults.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (vm.isLoadingPlayer)
          const _ReportCard(child: Center(child: CircularProgressIndicator()))
        else if (physical == null && skill == null && rating == null)
          const _EmptyAssessmentCard(
            icon: Icons.trending_up,
            title: 'No progress data yet',
            subtitle: 'Progress appears once assessments are recorded.',
          )
        else ...[
          if (rating != null) _RatingCard(rating: rating),
          if (rating != null) const SizedBox(height: 12),
          _ReportCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latest Physical',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (physical == null)
                  Text(
                    'No physical result yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  ..._metricRows(
                    physical.metrics,
                    metricDefinitions,
                    MetricCategory.physical,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latest Skills',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (skill == null)
                  Text(
                    'No skill result yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  ..._metricRows(
                    skill.metrics,
                    metricDefinitions,
                    MetricCategory.skill,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Matches',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (recentMatches.isEmpty)
                  Text(
                    'No match results yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  ...recentMatches.map(
                    (match) => _MatchRow(
                      opponent: match.opponentName,
                      score: '${match.myPoints}-${match.opponentPoints}',
                      isWin: match.isWin,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _metricRows(
    Map<String, dynamic> values,
    List<MetricDefinitionModel> definitions,
    String category,
  ) {
    final definitionMap = {
      for (final definition in definitions.where((d) => d.category == category))
        definition.key: definition,
    };

    return values.entries.map((entry) {
      final definition = definitionMap[entry.key];
      final raw = entry.value is num
          ? entry.value as num
          : num.tryParse(entry.value?.toString() ?? '');
      final score = definition == null ? null : definition.scoreFor(raw) / 10;
      return _MetricRow(
        definition?.label ?? entry.key,
        score,
      );
    }).toList();
  }

  String _scoreOutOfTen(double score) {
    return '${(score.clamp(0.0, 100.0) / 10).toStringAsFixed(1)}/10';
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSummarySection(ParentViewModel parentVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'AI Improvement Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Icon(Icons.auto_awesome,
                size: 18, color: AppTheme.primaryColor),
          ],
        ),
        const SizedBox(height: 12),
        if (parentVM.isGeneratingSummary)
          const _ReportCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (parentVM.summaryError != null)
          _ReportCard(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text(
                  parentVM.summaryError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      parentVM.generateAiSummary(widget.playerId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (parentVM.aiSummary == null)
          _ReportCard(
            child: Column(
              children: [
                Icon(Icons.auto_awesome_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'Get an AI-powered summary of your child\'s progress based on coach observations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      parentVM.generateAiSummary(widget.playerId),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generate Summary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          _ReportCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._parseSummarySections(parentVM.aiSummary!),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        parentVM.generateAiSummary(widget.playerId),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Regenerate'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _parseSummarySections(String summary) {
    final widgets = <Widget>[];
    final sections = summary.split(RegExp(r'^## ', multiLine: true))
        .where((s) => s.trim().isNotEmpty);

    for (final section in sections) {
      final lines = section.split('\n');
      final title = lines.first.trim();
      final content = lines.skip(1).join('\n').trim();

      if (content.isEmpty) continue;

      final color = _sectionColor(title);
      final icon = _sectionIcon(title);

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(Text(
        summary,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.5),
      ));
    }

    return widgets;
  }

  Color _sectionColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('strength')) return Colors.green;
    if (lower.contains('improve') || lower.contains('area')) return Colors.orange;
    if (lower.contains('suggest') || lower.contains('home') || lower.contains('practice')) return Colors.blue;
    return AppTheme.primaryColor;
  }

  IconData _sectionIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('strength')) return Icons.thumb_up_outlined;
    if (lower.contains('improve') || lower.contains('area')) return Icons.trending_up;
    if (lower.contains('suggest') || lower.contains('home') || lower.contains('practice')) return Icons.lightbulb_outline;
    return Icons.info_outline;
  }

  Widget _buildPendingNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This player is pending admin approval. Some features may be limited.',
              style: TextStyle(color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Widget child;

  const _ReportCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyAssessmentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyAssessmentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double? score;

  const _ScoreBar({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final value = (score ?? 0).clamp(0.0, 100.0);
    final hasScore = score != null;
    final display = (value / 10).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                hasScore ? '$display/10' : '—',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: hasScore ? value / 100 : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String trend;

  const _TrendBadge({required this.trend});

  @override
  Widget build(BuildContext context) {
    final isUp = trend == CssTrend.up;
    final isDown = trend == CssTrend.down;
    final color = isUp ? Colors.green : (isDown ? Colors.red : Colors.grey);
    final icon = isUp
        ? Icons.trending_up
        : (isDown ? Icons.trending_down : Icons.trending_flat);
    final label = isUp ? 'Improving' : (isDown ? 'Needs focus' : 'Stable');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final PlayerRatingModel rating;

  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            child: Icon(Icons.emoji_events, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rating.tier,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rating.matchCount} matches • ${rating.winRate.toStringAsFixed(0)}% win rate',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double? score;

  const _MetricRow(this.label, this.score);

  @override
  Widget build(BuildContext context) {
    final text = score == null ? '—' : '${score!.toStringAsFixed(1)}/10';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final String opponent;
  final String score;
  final bool isWin;

  const _MatchRow({
    required this.opponent,
    required this.score,
    required this.isWin,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWin ? Colors.green : Colors.red;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(opponent)),
          Text(score, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isWin ? 'Win' : 'Loss',
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
