package com.healthcompanion.health_companion

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetPlugin

class HealthWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId, widgetData, null)
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val widgetData = context.getSharedPreferences("es.antonborri.home_widget.preferences", Context.MODE_PRIVATE)
        updateWidget(context, appWidgetManager, appWidgetId, widgetData, newOptions)
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int, widgetData: SharedPreferences, options: Bundle?) {
        val views = RemoteViews(context.packageName, R.layout.health_widget).apply {
            val hr = widgetData.getString("hr", "--")
            val spo2 = widgetData.getString("spo2", "--")
            val temp = widgetData.getString("temp", "--")
            val steps = widgetData.getString("steps", "--")
            val sleep = widgetData.getString("sleep", "--")

            setTextViewText(R.id.tv_hr, "$hr bpm")
            setTextViewText(R.id.tv_spo2, "$spo2 %")
            setTextViewText(R.id.tv_temp, "$temp °C")
            setTextViewText(R.id.tv_steps, "$steps")
            setTextViewText(R.id.tv_sleep, "$sleep")

            val currentOptions = options ?: appWidgetManager.getAppWidgetOptions(widgetId)
            val minWidth = currentOptions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val minHeight = currentOptions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

            // If the widget is tall enough, show extra data (steps and sleep)
            if (minHeight > 100) {
                setViewVisibility(R.id.layout_extra, View.VISIBLE)
            } else {
                setViewVisibility(R.id.layout_extra, View.GONE)
            }
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
