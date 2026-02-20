import Highcharts from "highcharts"
import { isObject } from "helpers/object_helpers"

export const getHoverPoint = (chart, e) => {
  return chart.pointer.findNearestKDPoint(chart.series, true, chart.pointer.normalize(e))
}

export const syncZoomReset = e => {
  if (!e.resetSelection) return

  Highcharts.charts.forEach(chart => {
    if (!isObject(chart) || !isObject(chart.resetZoomButton)) return
    chart.resetZoomButton = chart.resetZoomButton.destroy()
  })
}

export const syncExtremes = function (e) {
  if (e.trigger === "syncExtremes") return

  Highcharts.charts.forEach(chart => {
    if (!isObject(chart) || chart === this.chart) return
    if (!chart.xAxis[0].setExtremes) return

    chart.xAxis[0].setExtremes(e.min, e.max, undefined, false, { trigger: "syncExtremes" })
    if (isObject(chart.resetZoomButton) || e.min === undefined || e.max === undefined) return

    chart.showResetZoom()
  })
}

export const isDark = () => {
  if (document.body.classList.contains("system")) {
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
  } else {
    return document.body.classList.contains("dark")
  }
}

const cssColor = name => getComputedStyle(document.documentElement).getPropertyValue(name)

export const getColors = () => {
  if (isDark()) {
    return {
      background: cssColor("--color-neutral-900"),
      label: cssColor("--color-neutral-400"),
      gridLine: cssColor("--color-neutral-800"),
      line: cssColor("--color-neutral-700"),
      legend: cssColor("--color-neutral-300"),
      legendHover: cssColor("--color-white"),
      legendHidden: cssColor("--color-neutral-700")
    }
  } else {
    return {
      background: cssColor("--color-white"),
      label: cssColor("--color-neutral-600"),
      gridLine: cssColor("--color-neutral-200"),
      line: cssColor("--color-neutral-300"),
      legend: cssColor("--color-neutral-700"),
      legendHover: cssColor("--color-neutral-900"),
      legendHidden: cssColor("--color-neutral-300")
    }
  }
}

export const commonOptions = () => {
  const colors = getColors()

  return {
    accessibility: { enabled: false },
    animation: false,
    title: false,
    chart: {
      zoomType: "x",
      backgroundColor: colors.background,
      events: { selection: syncZoomReset }
    },
    xAxis: {
      type: "datetime",
      events: { setExtremes: syncExtremes },
      crosshair: true,
      labels: {
        style: { color: colors.label },
        formatter: function () {
          if (this.value < 0) {
            return `-${Highcharts.dateFormat("%M:%S", -this.value)}`
          } else {
            return Highcharts.dateFormat("%M:%S", this.value)
          }
        }
      },
      gridLineColor: colors.gridLine,
      lineColor: colors.line,
      tickColor: colors.line
    },
    yAxis: {
      title: false,
      labels: { style: { color: colors.label } },
      gridLineColor: colors.gridLine,
      lineColor: colors.line,
      tickColor: colors.line
    },
    tooltip: {
      animation: false,
      shared: true,
      borderRadius: 10,
      shadow: false,
      borderWidth: 0,
      formatter: function (tooltip) {
        let s
        if (this.x < 0) {
          s = [`-${Highcharts.dateFormat("%M:%S.%L", -this.x)}<br>`]
        } else {
          s = [`${Highcharts.dateFormat("%M:%S.%L", this.x)}<br>`]
        }

        const visibleSeries = this.points.filter(point => point.series.visible)
        if (visibleSeries.length === 2) {
          const [series1, series2] = visibleSeries
          const diff = Math.abs(series1.y - series2.y)
          const formattedDiff = Highcharts.numberFormat(diff, 2)
          s = s.concat(tooltip.bodyFormatter(visibleSeries))
          s.push(`Δ <strong>${formattedDiff}</strong>`)
        } else {
          s = s.concat(tooltip.bodyFormatter(this.points))
        }

        return s
      }
    },
    legend: {
      itemStyle: { color: colors.legend },
      itemHoverStyle: { color: colors.legendHover },
      itemHiddenStyle: { color: colors.legendHidden }
    },
    plotOptions: {
      series: {
        animation: false,
        marker: {
          enabled: false,
          states: { hover: { enabled: false } }
        },
        states: {
          hover: { enabled: false },
          inactive: { enabled: false }
        }
      }
    },
    credits: { enabled: false }
  }
}
