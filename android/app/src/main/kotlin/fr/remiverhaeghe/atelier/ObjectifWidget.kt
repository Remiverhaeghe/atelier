package fr.remiverhaeghe.atelier

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

// Widget d'écran d'accueil : l'appli écrit les lignes, le widget les affiche et ouvre l'appli
class ObjectifWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (vWidgetId in appWidgetIds) {
            val vViews = RemoteViews(context.packageName, R.layout.objectif_widget).apply {
                setTextViewText(R.id.widget_title, widgetData.getString("title", "Atelier"))
                setTextViewText(R.id.widget_goal, widgetData.getString("goal", ""))
                setTextViewText(R.id.widget_wait, widgetData.getString("wait", ""))
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(vWidgetId, vViews)
        }
    }
}
