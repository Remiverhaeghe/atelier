import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/extra_items.dart';
import '../logic/gestures.dart';
import '../logic/right_tool.dart';
import '../logic/units.dart';
import 'gestures_screen.dart';
import 'parquet_view.dart';
import 'shopping_target.dart';
import 'starter_tools_screen.dart';
import 'theme.dart';

String toolTaskName(AppLocalizations pText, ToolTask pTask) => switch (pTask) {
  ToolTask.cutBoards => pText.taskCutBoards,
  ToolTask.cutCurves => pText.taskCutCurves,
  ToolTask.drillConcrete => pText.taskDrillConcrete,
  ToolTask.screwMany => pText.taskScrewMany,
  ToolTask.sandFurniture => pText.taskSandFurniture,
  ToolTask.sandFloor => pText.taskSandFloor,
  ToolTask.cutTiles => pText.taskCutTiles,
  ToolTask.mixPlaster => pText.taskMixPlaster,
  ToolTask.demolish => pText.taskDemolish,
  ToolTask.mitreCuts => pText.taskMitreCuts,
};

String powerToolName(AppLocalizations pText, PowerTool pTool) => switch (pTool) {
  PowerTool.circularSaw => pText.powerCircularSaw,
  PowerTool.jigsaw => pText.powerJigsaw,
  PowerTool.hammerDrill => pText.powerHammerDrill,
  PowerTool.drillDriver => pText.powerDrillDriver,
  PowerTool.sander => pText.powerSander,
  PowerTool.floorSander => pText.powerFloorSander,
  PowerTool.tileCutter => pText.powerTileCutter,
  PowerTool.mixer => pText.powerMixer,
  PowerTool.breaker => pText.powerBreaker,
  PowerTool.mitreSaw => pText.powerMitreSaw,
};

String toolChoiceLabel(AppLocalizations pText, ToolChoice pChoice) => switch (pChoice) {
  ToolChoice.manual => pText.rightToolChoiceManual,
  ToolChoice.borrow => pText.rightToolChoiceBorrow,
  ToolChoice.rent => pText.rightToolChoiceRent,
  ToolChoice.buy => pText.rightToolChoiceBuy,
};

/// Le bon outil : pour une tâche et un nombre de jours, à la main ou électrique, et acheter,
/// louer ou emprunter.
class RightToolScreen extends StatefulWidget {
  const RightToolScreen({super.key});

  @override
  State<RightToolScreen> createState() => _RightToolScreenState();
}

class _RightToolScreenState extends State<RightToolScreen> {
  var _task = ToolTask.cutBoards;
  var _days = 1;
  var _ownsManual = false;
  var _canBorrow = false;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vAdvice = adviseTool(_task, _days, pOwnsManual: _ownsManual, pCanBorrow: _canBorrow);
    final vManual = _task.manual;
    final vPower = _task.power;
    final vGestures = vManual == null ? const <Gesture>[] : gesturesWith(vManual);

    return Scaffold(
      appBar: AppBar(title: Text(vText.rightToolTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(vText.rightToolIntro, style: vTheme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<ToolTask>(
            isExpanded: true,
            initialValue: _task,
            decoration: InputDecoration(labelText: vText.rightToolTask),
            items: [
              for (final vTask in ToolTask.values)
                DropdownMenuItem(value: vTask, child: Text(toolTaskName(vText, vTask))),
            ],
            onChanged: (pTask) => setState(() => _task = pTask!),
          ),
          NumberField<int>(
            label: vText.rightToolDays,
            initial: '$_days',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _days = pValue),
          ),
          if (vManual != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(vText.rightToolOwnsManual),
              value: _ownsManual,
              onChanged: (pValue) => setState(() => _ownsManual = pValue),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.rightToolCanBorrow),
            value: _canBorrow,
            onChanged: (pValue) => setState(() => _canBorrow = pValue),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(toolChoiceLabel(vText, vAdvice.choice)),
                  IconLine(Icons.euro, vText.rightToolBudget(vAdvice.budgetEuros)),
                  IconLine(
                    Icons.handyman_outlined,
                    vManual == null
                        ? vText.rightToolNoManual
                        : vText.rightToolManual(
                            toolName(vText, vManual),
                            vManual.minEuros,
                            vManual.maxEuros,
                          ),
                  ),
                  IconLine(
                    Icons.electrical_services,
                    vText.rightToolPower(
                      powerToolName(vText, vPower),
                      vPower.buyEuros,
                      vPower.dayEuros,
                    ),
                  ),
                  IconLine(Icons.event_outlined, vText.rightToolRentTotal(vAdvice.rentEuros)),
                  if (vAdvice.breakEvenDays case final vDays?)
                    IconLine(Icons.balance, vText.rentBreakEven(vDays)),
                  if (vAdvice.choice == ToolChoice.buy || vAdvice.choice == ToolChoice.manual)
                    AddToShoppingButton(
                      items: () => [
                        if (vAdvice.choice == ToolChoice.buy)
                          ExtraItem(name: powerToolName(vText, vPower), quantity: 1)
                        else if (!_ownsManual && vManual != null)
                          ExtraItem(name: toolName(vText, vManual), quantity: 1),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (vGestures.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(vText.rightToolGestures, style: vTheme.textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                for (final vGesture in vGestures)
                  ActionChip(
                    label: Text(gestureName(vText, vGesture)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => GestureScreen(gesture: vGesture)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
