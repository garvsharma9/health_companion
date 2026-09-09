package com.healthcompanion.health_companion

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ActivityWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int, widgetData: SharedPreferences) {
        val views = RemoteViews(context.packageName, R.layout.widget_activity).apply {
            val stepsStr = widgetData.getString("steps", "--")
            setTextViewText(R.id.tv_steps, stepsStr)
            
            try {
                val steps = stepsStr?.replace(",", "")?.toInt() ?: 0
                val progress = (steps.toFloat() / 10000f * 100).toInt()
                val progressClamped = if (progress > 100) 100 else progress
                setProgressBar(R.id.pb_activity, 10000, steps, false)
                setTextViewText(R.id.tv_progress_pct, "$progressClamped%")
            } catch (e: Exception) {
                setProgressBar(R.id.pb_activity, 10000, 0, false)
                setTextViewText(R.id.tv_progress_pct, "0%")
            }
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
