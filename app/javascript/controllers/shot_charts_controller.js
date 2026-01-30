import { Controller } from "@hotwired/stimulus"
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

const getHoverPoint = (chart, e) => {
  return chart.pointer.findNearestKDPoint(chart.series, true, chart.pointer.normalize(e))
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

export default class extends Controller {
  connect() {
    this.charts = []
    this.syncedElements = []
    this.syncMouse = this.syncMouse.bind(this)
    this.mouseLeave = this.mouseLeave.bind(this)
    this.handleColorSchemeChange = this.handleColorSchemeChange.bind(this)
    this.initializeCharts()

    this.colorSchemeMedia = window.matchMedia("(prefers-color-scheme: dark)")
    this.colorSchemeMedia.addEventListener("change", this.handleColorSchemeChange)
  }

  disconnect() {
    this.colorSchemeMedia?.removeEventListener("change", this.handleColorSchemeChange)
    this.detachComparisonAdjust()
    this.detachMouseSyncEvents()
    this.destroyCharts()
  }

  initializeCharts() {
    this.destroyCharts()

    const shotChart = this.element.querySelector("#shot-chart")
    if (shotChart) {
      this.shotData = this.parseArrayData(shotChart.dataset.shotData)
      this.shotStages = this.parseArrayData(shotChart.dataset.shotStages)
      this.comparisonData = this.parseObjectData(shotChart.dataset.comparisonData)

      if (this.shotData.length) {
        const chart = this.drawShotChart(shotChart)
        this.charts.push(chart)
        this.syncMouseEvents(shotChart)
      }
    }

    const temperatureChart = this.element.querySelector("#temperature-chart")
    if (temperatureChart) {
      this.temperatureData = this.parseArrayData(temperatureChart.dataset.temperatureData)

      if (this.temperatureData.length) {
        const chart = this.drawTemperatureChart(temperatureChart)
        this.charts.push(chart)
        this.syncMouseEvents(temperatureChart)
      }
    }

    this.attachComparisonAdjust()

    if (this.shotStages?.length > 0) {
      this.shotStages = this.shotStages.map(x => ({ ...x, id: x }))
      this.drawShotStages()
    }
  }

  parseArrayData(dataset) {
    if (!dataset) return []
    const parsed = JSON.parse(dataset)
    return Array.isArray(parsed) ? parsed : []
  }

  parseObjectData(dataset) {
    if (!dataset) return null
    const parsed = JSON.parse(dataset)
    return parsed && !Array.isArray(parsed) ? parsed : null
  }

  destroyCharts() {
    this.charts.forEach(chart => chart.destroy())
    this.charts = []
  }

  syncMouseEvents(element) {
    if (this.syncedElements.includes(element)) return
    element.addEventListener("mousemove", this.syncMouse)
    element.addEventListener("touchstart", this.syncMouse)
    element.addEventListener("touchmove", this.syncMouse)
    element.addEventListener("mouseleave", this.mouseLeave)
    this.syncedElements.push(element)
  }

  detachMouseSyncEvents() {
    this.syncedElements.forEach(element => {
      element.removeEventListener("mousemove", this.syncMouse)
      element.removeEventListener("touchstart", this.syncMouse)
      element.removeEventListener("touchmove", this.syncMouse)
      element.removeEventListener("mouseleave", this.mouseLeave)
    })
    this.syncedElements = []
  }

  syncMouse(e) {
    this.charts.forEach(chart => {
      if (!isObject(chart) || this.element !== chart.renderTo?.closest("[data-controller~='shot-charts']")) return

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

  mouseLeave(e) {
    this.charts.forEach(chart => {
      if (!isObject(chart)) return

      const hoverPoint = getHoverPoint(chart, e)

      if (hoverPoint) {
        hoverPoint.onMouseOut()
        chart.tooltip.hide(hoverPoint)
        chart.xAxis[0].hideCrosshair()
      }
    })
  }

  extractStages(field, timings) {
    for (const fieldData of this.shotData) {
      if (fieldData.name === field) {
        return timings.map(time => new Map(fieldData.data).get(time))
      }
    }
    return timings.map(() => 0)
  }

  setupInCupAnnotations(chart) {
    const weightColor = chart.series.find(x => x.name === "Weight Flow").color
    const timings = this.shotStages.map(x => x.value)
    const weightFlow = this.extractStages("Weight Flow", timings)
    const weight = this.extractStages("Weight", timings)

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
        chart.controller.destroyShotStages()
        chart.annotations[0].graphic.hide()
        chart.annotationVisible = false
        this.innerHTML = "Show annotations"
      } else {
        chart.controller.drawShotStages()
        chart.annotations[0].graphic.show()
        chart.annotationVisible = true
        this.innerHTML = "Hide annotations"
      }
    })
  }

  updateInCupVisibility(chart) {
    const weightFlowSeries = chart.series.filter(x => x.name === "Weight Flow" && x.visible)
    const isVisible = weightFlowSeries.length > 0
    const annotation = chart.inCupAnnotation

    if (annotation && !isVisible) {
      chart.removeAnnotation(annotation)
      chart.inCupAnnotation = null
    } else if (this.shotStages?.length > 0 && !annotation && isVisible) {
      this.setupInCupAnnotations(chart)
    }
  }

  drawShotChart(element) {
    const hasSecondaryAxis = this.shotData.some(series => series.yAxis === 1)
    const custom = {
      chart: {
        height: 650,
        events: { redraw: e => this.updateInCupVisibility(e.target) }
      },
      series: this.shotData
    }

    let options = deepMerge(commonOptions(), custom)
    if (hasSecondaryAxis) {
      const primaryAxis = options.yAxis
      options.yAxis = [
        primaryAxis,
        {
          ...primaryAxis,
          opposite: true,
          gridLineWidth: 0
        }
      ]
    }
    const chart = Highcharts.chart(element, options)
    chart.controller = this
    if (this.shotStages?.length > 0) {
      this.setupInCupAnnotations(chart)
    }
    return chart
  }

  drawShotStages() {
    this.charts.forEach(chart => {
      if (isObject(chart)) {
        this.shotStages.forEach(x => chart.xAxis[0].addPlotLine(x))
      }
    })
  }

  destroyShotStages() {
    this.charts.forEach(chart => {
      if (isObject(chart)) {
        while (chart.xAxis[0].plotLinesAndBands.length > 0) {
          chart.xAxis[0].plotLinesAndBands.forEach(plotLine => {
            chart.xAxis[0].removePlotLine(plotLine.id)
          })
        }
      }
    })
  }

  drawTemperatureChart(element) {
    const custom = {
      chart: {
        height: 400
      },
      series: this.temperatureData
    }

    let options = deepMerge(commonOptions(), custom)
    return Highcharts.chart(element, options)
  }

  attachComparisonAdjust() {
    this.compareRange = document.getElementById("compare-range")
    if (!this.compareRange || !this.comparisonData) return

    this.compareInputHandler = () => {
      const value = parseInt(this.compareRange.value)
      this.charts.forEach(chart => {
        if (isObject(chart)) {
          chart.series.forEach(s => {
            if (this.comparisonData[s.name]) {
              s.setData(
                this.comparisonData[s.name].map(d => [d[0] + value, d[1]]),
                true,
                false,
                false
              )
            }
          })
        }
      })
    }

    this.compareResetButton = document.getElementById("compare-range-reset")
    this.compareResetHandler = () => {
      this.compareRange.value = 0
      this.compareInputHandler()
    }

    this.compareRange.addEventListener("input", this.compareInputHandler)
    this.compareResetButton?.addEventListener("click", this.compareResetHandler)
  }

  detachComparisonAdjust() {
    if (this.compareRange && this.compareInputHandler) {
      this.compareRange.removeEventListener("input", this.compareInputHandler)
    }
    if (this.compareResetButton && this.compareResetHandler) {
      this.compareResetButton.removeEventListener("click", this.compareResetHandler)
    }
  }

  handleColorSchemeChange() {
    if (document.body.classList.contains("system")) {
      this.initializeCharts()
    }
  }
}
