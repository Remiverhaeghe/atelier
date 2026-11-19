import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/trades.dart';
import 'starter_tools_screen.dart';
import 'theme.dart';
import 'work_sheet_pdf.dart';

/// Par où commencer : les types de travaux rangés du plus facile au plus délicat.
class TradesScreen extends StatelessWidget {
  const TradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.tradesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(vText.tradesIntro, style: vTheme.textTheme.bodyMedium),
          ),
          for (final MapEntry(key: vLevel, value: vTrades) in tradesByLevel().entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Text(tradeLevelName(vText, vLevel), style: vTheme.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(tradeLevelHint(vText, vLevel), style: vTheme.textTheme.bodySmall),
            ),
            for (final vTrade in vTrades)
              Card(
                child: ListTile(
                  leading: Icon(_levelIcon(vLevel)),
                  title: Text(tradeName(vText, vTrade)),
                  subtitle: Text(
                    vText.tradeTime(
                      beginnerHours(vTrade).minHours,
                      beginnerHours(vTrade).maxHours,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => TradeScreen(trade: vTrade)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

IconData _levelIcon(TradeLevel pLevel) => switch (pLevel) {
  TradeLevel.easy => Icons.sentiment_satisfied_alt,
  TradeLevel.medium => Icons.trending_up,
  TradeLevel.pro => Icons.engineering_outlined,
};

/// Fiche d'un type de travaux : niveau, temps, outillage, erreurs classiques.
class TradeScreen extends StatelessWidget {
  const TradeScreen({super.key, required this.trade});

  final Trade trade;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vHours = beginnerHours(trade);
    final vBudget = tradeBudget(trade, const {});
    final vMistakes = tradeMistakes(vText, trade);
    final vProPart = tradeProPart(vText, trade);
    final vBuy = vText.tradeBuy(vBudget.toBuy, vBudget.buyMinEuros, vBudget.buyMaxEuros);
    final vRent = vBudget.toRent == 0
        ? null
        : vText.tradeRent(vBudget.toRent, vBudget.rentMinEuros, vBudget.rentMaxEuros);

    return Scaffold(
      appBar: AppBar(
        title: Text(tradeName(vText, trade)),
        actions: [
          PrintSheetButton(
            sheet: () => (
              title: tradeName(vText, trade),
              intro: tradeJob(vText, trade),
              measures: const [],
              results: [
                tradeLevelName(vText, trade.level),
                vText.tradeTime(vHours.minHours, vHours.maxHours),
                vBuy,
                if (vRent != null) vRent,
                if (vProPart != null) vProPart,
              ],
              buy: const [],
              steps: vMistakes,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Chip(
            avatar: Icon(_levelIcon(trade.level), size: 18),
            label: Text(tradeLevelName(vText, trade.level)),
          ),
          Text(tradeLevelHint(vText, trade.level), style: vTheme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.tradeJobTitle, style: vTheme.textTheme.titleSmall),
                  Text(tradeJob(vText, trade)),
                  const SizedBox(height: 8),
                  BigFigure(vText.tradeTime(vHours.minHours, vHours.maxHours)),
                  IconLine(Icons.timer_outlined, vText.tradeProTime(trade.proHours)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(vText.tradeToolsTitle, style: vTheme.textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: [
              for (final vTool in trade.tools)
                Chip(
                  avatar: const Icon(Icons.handyman_outlined, size: 18),
                  label: Text(toolName(vText, vTool)),
                ),
              for (final vTool in trade.extra)
                Chip(
                  avatar: Icon(
                    vTool.rent ? Icons.event_repeat_outlined : Icons.add_shopping_cart,
                    size: 18,
                  ),
                  label: Text(
                    vTool.rent
                        ? '${tradeToolName(vText, vTool)} (${vText.tradeRentTag})'
                        : tradeToolName(vText, vTool),
                  ),
                ),
            ],
          ),
          IconLine(Icons.euro, vBuy),
          if (vRent != null) IconLine(Icons.event_repeat_outlined, vRent),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const StarterToolsScreen()),
              ),
              icon: const Icon(Icons.home_repair_service_outlined),
              label: Text(vText.tradeToolsLink),
            ),
          ),
          const SizedBox(height: 8),
          Text(vText.tradeMistakesTitle, style: vTheme.textTheme.titleMedium),
          for (final vMistake in vMistakes)
            IconLine(Icons.report_gmailerrorred, vMistake, color: vTheme.colorScheme.error),
          if (vProPart != null) ...[
            const SizedBox(height: 12),
            Text(vText.tradeProPartTitle, style: vTheme.textTheme.titleMedium),
            Text(vProPart),
          ],
        ],
      ),
    );
  }
}

String tradeLevelName(AppLocalizations pText, TradeLevel pLevel) => switch (pLevel) {
  TradeLevel.easy => pText.tradeLevelEasy,
  TradeLevel.medium => pText.tradeLevelMedium,
  TradeLevel.pro => pText.tradeLevelPro,
};

String tradeLevelHint(AppLocalizations pText, TradeLevel pLevel) => switch (pLevel) {
  TradeLevel.easy => pText.tradeLevelEasyHint,
  TradeLevel.medium => pText.tradeLevelMediumHint,
  TradeLevel.pro => pText.tradeLevelProHint,
};

String tradeName(AppLocalizations pText, Trade pTrade) => switch (pTrade) {
  Trade.paint => pText.tradePaint,
  Trade.baseboards => pText.tradeBaseboards,
  Trade.parquet => pText.tradeParquet,
  Trade.insulation => pText.tradeInsulation,
  Trade.drywall => pText.tradeDrywall,
  Trade.tiling => pText.tradeTiling,
  Trade.joinery => pText.tradeJoinery,
  Trade.plumbing => pText.tradePlumbing,
  Trade.electricity => pText.tradeElectricity,
};

String tradeJob(AppLocalizations pText, Trade pTrade) => switch (pTrade) {
  Trade.paint => pText.tradeJobPaint,
  Trade.baseboards => pText.tradeJobBaseboards,
  Trade.parquet => pText.tradeJobParquet,
  Trade.insulation => pText.tradeJobInsulation,
  Trade.drywall => pText.tradeJobDrywall,
  Trade.tiling => pText.tradeJobTiling,
  Trade.joinery => pText.tradeJobJoinery,
  Trade.plumbing => pText.tradeJobPlumbing,
  Trade.electricity => pText.tradeJobElectricity,
};

List<String> tradeMistakes(AppLocalizations pText, Trade pTrade) => switch (pTrade) {
  Trade.paint => [pText.tradePaint1, pText.tradePaint2, pText.tradePaint3],
  Trade.baseboards => [pText.tradeBaseboards1, pText.tradeBaseboards2, pText.tradeBaseboards3],
  Trade.parquet => [pText.tradeParquet1, pText.tradeParquet2, pText.tradeParquet3],
  Trade.insulation => [pText.tradeInsulation1, pText.tradeInsulation2, pText.tradeInsulation3],
  Trade.drywall => [pText.tradeDrywall1, pText.tradeDrywall2, pText.tradeDrywall3],
  Trade.tiling => [pText.tradeTiling1, pText.tradeTiling2, pText.tradeTiling3],
  Trade.joinery => [pText.tradeJoinery1, pText.tradeJoinery2, pText.tradeJoinery3],
  Trade.plumbing => [pText.tradePlumbing1, pText.tradePlumbing2, pText.tradePlumbing3],
  Trade.electricity => [
    pText.tradeElectricity1,
    pText.tradeElectricity2,
    pText.tradeElectricity3,
  ],
};

/// Partage entre ce qu'on fait seul et ce qu'on confie, pour les travaux à confier à un pro.
String? tradeProPart(AppLocalizations pText, Trade pTrade) => switch (pTrade) {
  Trade.plumbing => pText.tradeProPartPlumbing,
  Trade.electricity => pText.tradeProPartElectricity,
  _ => null,
};

String tradeToolName(AppLocalizations pText, TradeTool pTool) => switch (pTool) {
  TradeTool.roller => pText.tradeToolRoller,
  TradeTool.tapingKnife => pText.tradeToolTapingKnife,
  TradeTool.notchedTrowel => pText.tradeToolNotchedTrowel,
  TradeTool.tileCutter => pText.tradeToolTileCutter,
  TradeTool.mixer => pText.tradeToolMixer,
  TradeTool.boardLifter => pText.tradeToolBoardLifter,
  TradeTool.pullBar => pText.tradeToolPullBar,
  TradeTool.voltageTester => pText.tradeToolVoltageTester,
  TradeTool.pipeCutter => pText.tradeToolPipeCutter,
  TradeTool.jigsaw => pText.tradeToolJigsaw,
  TradeTool.insulationKnife => pText.tradeToolInsulationKnife,
  TradeTool.stapler => pText.tradeToolStapler,
};
