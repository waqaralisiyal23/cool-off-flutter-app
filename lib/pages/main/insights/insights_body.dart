import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../bloc/settings_bloc.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../engine/auto_tune.dart';
import '../../../models/data/user_settings_data.dart';
import '../../../stats/insights.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/fade_slide_in.dart';
import 'bloc/insights_bloc.dart';

class InsightsBody extends StatelessWidget {
  const InsightsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: InsightsBlocSelector.insights(
        builder: (insights) {
          if (insights == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            children: [
              const Text('Insights', style: AppTypography.extraBold32),
              const SizedBox(height: AppSpacing.xxs),
              const Text(
                'From your checks on this phone.',
                style: AppTypography.regular14,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (insights.isEmpty)
                const _Empty()
              else ...[
                FadeSlideIn(child: _Hero(insights: insights)),
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: _Tiles(insights: insights),
                ),
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _Week(insights: insights),
                ),
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: _Learning(insights: insights),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.insights_rounded, size: 40, color: AppColors.primary),
          SizedBox(height: AppSpacing.sm),
          Text('Nothing yet', style: AppTypography.bold20),
          SizedBox(height: AppSpacing.xs),
          Text(
            'After your first check you will see how often you cooled off, how '
            'your pulse drops during a cool-down, and what you thought the next '
            'morning.',
            style: AppTypography.regular14,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Insights insights;

  const _Hero({required this.insights});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: AppColors.calm,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: insights.cooledOff.toDouble()),
              duration: AppMotion.reveal,
              curve: AppMotion.emphasized,
              builder: (context, value, _) => Text(
                '${value.round()}',
                style: AppTypography.number64.copyWith(color: AppColors.calm),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insights.cooledOff == 1
                      ? 'message cooled off'
                      : 'messages cooled off',
                  // The number itself is excluded from semantics above.
                  semanticsLabel:
                      '${insights.cooledOff} '
                      '${insights.cooledOff == 1 ? 'message' : 'messages'} '
                      'cooled off',
                  style: AppTypography.semiBold18,
                ),
                const SizedBox(height: AppSpacing.xxs),
                const Text(
                  'Warm or heated messages you held, cooled down on, edited or deleted.',
                  style: AppTypography.regular12,
                ),
              ],
            ),
          ),
          const Icon(Icons.ac_unit_rounded, color: AppColors.calm, size: 32),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  final Insights insights;

  const _Tiles({required this.insights});

  @override
  Widget build(BuildContext context) {
    final drop = insights.averagePulseDrop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  label: 'Checks',
                  value: '${insights.totalChecks}',
                  detail:
                      '${insights.calm} calm · ${insights.warm} warm · ${insights.heated} heated',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Tile(
                  label: 'Cool-down pulse',
                  value: drop == null
                      ? '–'
                      : '${drop >= 0 ? '−' : '+'}${drop.abs().round()}',
                  unit: drop == null ? null : 'bpm',
                  detail: insights.cooldowns == 0
                      ? 'Try one on a heated result'
                      : 'average over ${insights.cooldowns} cool-down${insights.cooldowns == 1 ? '' : 's'}',
                  color: AppColors.calm,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Tile(
          label: 'Sent while heated',
          value: '${insights.heatedSends}',
          detail: insights.checkinsAnswered == 0
              ? 'Morning check-ins will show how those felt later.'
              : 'Regretted ${insights.regretted} of ${insights.checkinsAnswered} the next morning.',
          color: insights.heatedSends == 0 ? null : AppColors.heated,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String detail;
  final Color? color;

  const _Tile({
    required this.label,
    required this.value,
    required this.detail,
    this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTypography.medium12),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTypography.number40.copyWith(color: color),
                ),
                if (unit != null) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  Text(unit!, style: AppTypography.regular12),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(detail, style: AppTypography.regular12),
        ],
      ),
    );
  }
}

class _Week extends StatelessWidget {
  final Insights insights;

  const _Week({required this.insights});

  @override
  Widget build(BuildContext context) {
    final maxY = insights.week
        .fold<int>(1, (m, d) => d.total > m ? d.total : m)
        .toDouble();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LAST 7 DAYS', style: AppTypography.medium12),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: _summary(insights),
            child: ExcludeSemantics(
              child: SizedBox(
                height: 140,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: const BarTouchData(enabled: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              DateFormat.E()
                                  .format(insights.week[value.toInt()].day)
                                  .substring(0, 2),
                              style: AppTypography.regular12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < insights.week.length; i++)
                        _group(i, insights.week[i]),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              _Legend(color: AppColors.calm, label: 'Calm'),
              _Legend(color: AppColors.warm, label: 'Warm'),
              _Legend(color: AppColors.heated, label: 'Heated'),
            ],
          ),
        ],
      ),
    );
  }

  /// The chart in words, for screen readers.
  static String _summary(Insights insights) {
    final days = insights.week.where((d) => d.total > 0);
    if (days.isEmpty) {
      return 'Last 7 days: no checks.';
    }
    final parts = days.map(
      (d) =>
          '${DateFormat.EEEE().format(d.day)}: ${d.calm} calm, '
          '${d.warm} warm, ${d.heated} heated',
    );
    return 'Last 7 days. ${parts.join('; ')}.';
  }

  static BarChartGroupData _group(int x, DayHeat day) {
    final calm = day.calm.toDouble();
    final warm = calm + day.warm;
    final heated = warm + day.heated;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: day.total == 0 ? 0.04 : heated,
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          color: day.total == 0 ? AppColors.border : null,
          rodStackItems: day.total == 0
              ? const []
              : [
                  BarChartRodStackItem(0, calm, AppColors.calm),
                  BarChartRodStackItem(calm, warm, AppColors.warm),
                  BarChartRodStackItem(warm, heated, AppColors.heated),
                ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: AppTypography.regular12),
        ],
      ),
    );
  }
}

/// What the next-morning check-ins have taught the app (auto-tune).
class _Learning extends StatelessWidget {
  final Insights insights;

  const _Learning({required this.insights});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingsBloc, UserSettingsData?, int>(
      selector: (settings) => settings?.autoTuneOffset ?? 0,
      builder: (context, offset) {
        final needed = AutoTune.minAnswers - insights.checkinsAnswered;
        final (icon, text) = switch (offset) {
          < 0 => (
            Icons.shield_moon_rounded,
            'Your check-ins say heated sends often felt wrong the next morning, '
                'so Cool Off now calls Heated a little sooner.',
          ),
          > 0 => (
            Icons.thumb_up_alt_rounded,
            'Your check-ins say your heated sends usually felt fine, so Cool Off '
                'now waits for a bit more heat before calling Heated.',
          ),
          _ when needed > 0 => (
            Icons.school_rounded,
            'Answer $needed more morning check-in${needed == 1 ? '' : 's'} and '
                'Cool Off will tune its sensitivity to you.',
          ),
          _ => (
            Icons.balance_rounded,
            'Your check-ins are balanced, so the sensitivity stays as it is.',
          ),
        };
        return AppCard(
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(text, style: AppTypography.regular14)),
            ],
          ),
        );
      },
    );
  }
}
