package com.healthcompanion.health_companion

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SleepWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int, widgetData: SharedPreferences) {
        val views = RemoteViews(context.packageName, R.layout.widget_sleep).apply {
            val sleepH = widgetData.getString("sleep_h", "--")
            val sleepM = widgetData.getString("sleep_m", "--")
            setTextViewText(R.id.tv_sleep_h, sleepH)
            setTextViewText(R.id.tv_sleep_m, sleepM)
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
