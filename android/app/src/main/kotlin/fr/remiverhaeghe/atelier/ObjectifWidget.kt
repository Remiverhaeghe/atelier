package fr.remiverhaeghe.atelier

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.io.File
import org.json.JSONObject

// Widget d'écran d'accueil : l'appli écrit widget.json dans son dossier, le widget le relit
// quand on le pose puis toutes les 30 minutes, et ouvre l'appli d'un appui
class ObjectifWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        // Dossier de getApplicationDocumentsDirectory() côté Flutter
        val vFile = File(context.getDir("flutter", Context.MODE_PRIVATE), "widget.json")
        val vData = try {
            JSONObject(vFile.readText())
        } catch (pError: Exception) {
            JSONObject()
        }
        val vOpen = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        for (vWidgetId in appWidgetIds) {
            val vViews = RemoteViews(context.packageName, R.layout.objectif_widget).apply {
                setTextViewText(R.id.widget_title, vData.optString("title", "Atelier"))
                setTextViewText(R.id.widget_goal, vData.optString("goal", ""))
                setTextViewText(R.id.widget_wait, vData.optString("wait", ""))
                setOnClickPendingIntent(R.id.widget_root, vOpen)
            }
            appWidgetManager.updateAppWidget(vWidgetId, vViews)
        }
    }
}
