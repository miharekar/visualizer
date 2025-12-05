import Highcharts from "highcharts"
import "highcharts-annotations"

const deepMerge = (obj1, obj2) => {
  const result = { ...obj1 }
  for (const key in obj2) {
    if (!obj2.hasOwnProperty(key)) return

    if (obj2[key] instanceof Object && obj1[key] instanceof Object) {
      result[key] = deepMerge(obj1[key], obj2[key])
    } else {
      result[key] = obj2[key]
    }
  }
  return result
}

const isObject = obj => obj && typeof obj === "object"

const syncMouseEvents = element => {
  element.addEventListener("mousemove", syncMouse)
  element.addEventListener("touchstart", syncMouse)
  element.addEventListener("touchmove", syncMouse)
  element.addEventListener("mouseleave", mouseLeave)
}

const getHoverPoint = (chart, e) => {
  return chart.pointer.findNearestKDPoint(chart.series, true, chart.pointer.normalize(e))
}

function syncMouse(e) {
  Highcharts.charts.forEach(chart => {
    if (!isObject(chart) || this === chart.renderTo) return

    const hoverPoint = getHoverPoint(chart, e)
    const hoverPoints = []

    if (hoverPoint) {
      chart.series.forEach(s => {
        if (!s.visible) return

        const point = s.points.find(p => p.x === hoverPoint.x && !p.isNull)
        if (isObject(point)) {
          hoverPoints.push(point)
        }
      })
    }

    if (hoverPoints.length) {
      chart.tooltip.refresh(hoverPoints)
      chart.xAxis[0].drawCrosshair(e, hoverPoints[0])
    }
  })
}

const mouseLeave = e => {
  Highcharts.charts.forEach(chart => {
    if (!isObject(chart)) return

    const hoverPoint = getHoverPoint(chart, e)

    if (hoverPoint) {
      hoverPoint.onMouseOut()
      chart.tooltip.hide(hoverPoint)
      chart.xAxis[0].hideCrosshair()
    }
  })
}

const syncZoomReset = e => {
  if (!e.resetSelection) return

  Highcharts.charts.forEach(chart => {
    if (!isObject(chart) || !isObject(chart.resetZoomButton)) return
    chart.resetZoomButton = chart.resetZoomButton.destroy()
  })
}

const syncExtremes = function (e) {
  if (e.trigger === "syncExtremes") return

  Highcharts.charts.forEach(chart => {
    if (!isObject(chart) || chart === this.chart) return
    if (!chart.xAxis[0].setExtremes) return

    chart.xAxis[0].setExtremes(e.min, e.max, undefined, false, { trigger: "syncExtremes" })
    if (isObject(chart.resetZoomButton) || e.min === undefined || e.max === undefined) return

    chart.showResetZoom()
  })
}

const isDark = () => {
  if (document.body.classList.contains("system")) {
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
  } else {
    return document.body.classList.contains("dark")
  }
}

const getColors = () => {
  if (isDark()) {
    return {
      background: "#171717",
      label: "#999999",
      gridLine: "#191919",
      line: "#332914",
      legend: "#cccccc",
      legendHover: "#ffffff",
      legendHidden: "#333333"
    }
  } else {
    return {
      background: "#ffffff",
      label: "#666666",
      gridLine: "#e6e6e6",
      line: "#ccd6eb",
      legend: "#333333",
      legendHover: "#000000",
      legendHidden: "#cccccc"
    }
  }
}

const commonOptions = () => {
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

const extractStages = (field, timings) => {
  for (const fieldData of window.shotData) {
    if (fieldData.name === field) {
      return timings.map(time => new Map(fieldData.data).get(time))
    }
  }
  return timings.map(() => 0)
}

function setupInCupAnnotations(chart) {
  const weightColor = chart.series.find(x => x.name === "Weight Flow").color
  const timings = shotStages.map(x => x.value)
  const weightFlow = extractStages("Weight Flow", timings)
  const weight = extractStages("Weight", timings)

  let labels = []
  timings.forEach((timing, index) => {
    const inCup = weight[index]
    if (inCup > 0) {
      labels.push({
        text: `${inCup}g`,
        point: { x: timing, y: weightFlow[index], xAxis: 0, yAxis: 0 },
        y: -30,
        x: -30,
        allowOverlap: true,
        style: { color: weightColor },
        borderColor: weightColor
      })
    }
  })

  chart.inCupAnnotation = chart.addAnnotation({
    draggable: false,
    labels: labels,
    labelOptions: { shape: "connector" }
  })

  chart.renderer.text('<button id="remove-annotations" class="inline-flex py-1 px-2 text-xs font-medium bg-white rounded border shadow-sm cursor-pointer highcharts-no-tooltip border-neutral-300 text-neutral-700 dark:border-neutral-600 dark:bg-neutral-800 dark:text-neutral-300 dark:hover:bg-neutral-900 hover:bg-neutral-50">Hide annotations</span>', 50, 35, true).attr({ zIndex: 3 }).add()
  chart.annotationVisible = true
  document.getElementById("remove-annotations").addEventListener("click", function () {
    if (chart.annotationVisible) {
      destroyShotStages()
      chart.annotations[0].graphic.hide()
      chart.annotationVisible = false
      this.innerHTML = "Show annotations"
    } else {
      drawShotStages()
      chart.annotations[0].graphic.show()
      chart.annotationVisible = true
      this.innerHTML = "Hide annotations"
    }
  })
}

function updateInCupVisibility(chart) {
  const weightFlowSeries = chart.series.filter(x => x.name === "Weight Flow" && x.visible)
  const isVisible = weightFlowSeries.length > 0
  const annotation = chart.inCupAnnotation

  if (annotation && !isVisible) {
    chart.removeAnnotation(annotation)
    chart.inCupAnnotation = null
  } else if (window.shotStages?.length > 0 && !annotation && isVisible) {
    setupInCupAnnotations(chart)
  }
}

function drawShotChart() {
  const custom = {
    chart: {
      height: 650,
      events: { redraw: e => updateInCupVisibility(e.target) }
    },
    series: window.shotData
  }

  let options = deepMerge(commonOptions(), custom)
  let chart = Highcharts.chart("shot-chart", options)
  if (window.shotStages?.length > 0) {
    setupInCupAnnotations(chart)
  }
}

function destroyShotStages() {
  Highcharts.charts.forEach(chart => {
    if (isObject(chart)) {
      while (chart.xAxis[0].plotLinesAndBands.length > 0) {
        chart.xAxis[0].plotLinesAndBands.forEach(plotLine => {
          chart.xAxis[0].removePlotLine(plotLine.id)
        })
      }
    }
  })
}

function drawShotStages() {
  Highcharts.charts.forEach(chart => {
    if (isObject(chart)) {
      window.shotStages.forEach(x => chart.xAxis[0].addPlotLine(x))
    }
  })
}

function drawTemperatureChart() {
  const custom = {
    chart: {
      height: 400
    },
    series: window.temperatureData
  }

  let options = deepMerge(commonOptions(), custom)
  Highcharts.chart("temperature-chart", options)
}

const comparisonAdjust = range => {
  range.addEventListener("input", function () {
    const value = parseInt(this.value)
    Highcharts.charts.forEach(chart => {
      if (isObject(chart)) {
        chart.series.forEach(s => {
          if (window.comparisonData[s.name]) {
            s.setData(
              window.comparisonData[s.name].map(d => [d[0] + value, d[1]]),
              true,
              false,
              false
            )
          }
        })
      }
    })
  })
  document.getElementById("compare-range-reset").addEventListener("click", function () {
    range.value = 0
    range.dispatchEvent(new Event("input"))
  })
}

document.addEventListener("turbo:load", () => {
  Highcharts.charts.forEach(chart => {
    if (isObject(chart) && chart.renderTo && !chart.renderTo.hasAttribute("data-controller")) {
      chart.destroy()
    }
  })

  const shotChart = document.getElementById("shot-chart")
  if (shotChart) {
    drawShotChart()
    syncMouseEvents(shotChart)
  }

  const temperatureChart = document.getElementById("temperature-chart")
  if (temperatureChart) {
    drawTemperatureChart()
    syncMouseEvents(temperatureChart)
  }

  const range = document.getElementById("compare-range")
  if (range) {
    comparisonAdjust(range)
  }

  if (window.shotStages?.length > 0) {
    window.shotStages = window.shotStages.map(x => ({ ...x, id: x }))
    drawShotStages()
  }
})

window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
  if (document.body.classList.contains("system")) {
    if (document.getElementById("shot-chart")) {
      drawShotChart()
    }

    if (document.getElementById("temperature-chart")) {
      drawTemperatureChart()
    }
  }
})
