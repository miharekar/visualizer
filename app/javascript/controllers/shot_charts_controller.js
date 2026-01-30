import { Controller } from "@hotwired/stimulus"
import Highcharts from "highcharts"
import "highcharts-annotations"
import { commonOptions, getHoverPoint } from "helpers/shot_chart_helpers"
import { deepMerge, isObject } from "helpers/object_helpers"

export default class extends Controller {
  static targets = ["shotChart", "temperatureChart", "compareRange", "compareReset"]
  static values = { shotData: Array, shotStages: Array, temperatureData: Array, comparisonData: Object }

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
    this.detachMouseSyncEvents()
    this.destroyCharts()
  }

  initializeCharts() {
    this.destroyCharts()
    this.shotStagesNormalized = this.shotStagesValue.map(x => ({ ...x, id: x }))

    if (this.hasShotChartTarget && this.shotDataValue.length) {
      const chart = this.drawShotChart(this.shotChartTarget)
      this.charts.push(chart)
      this.syncMouseEvents(this.shotChartTarget)
    }

    if (this.hasTemperatureChartTarget && this.temperatureDataValue.length) {
      const chart = this.drawTemperatureChart(this.temperatureChartTarget)
      this.charts.push(chart)
      this.syncMouseEvents(this.temperatureChartTarget)
    }

    if (this.shotStagesNormalized.length > 0) {
      this.drawShotStages()
    }
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
    for (const fieldData of this.shotDataValue) {
      if (fieldData.name === field) {
        return timings.map(time => new Map(fieldData.data).get(time))
      }
    }
    return timings.map(() => 0)
  }

  setupInCupAnnotations(chart) {
    const weightColor = chart.series.find(x => x.name === "Weight Flow").color
    const timings = this.shotStagesNormalized.map(x => x.value)
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
    } else if (this.shotStagesNormalized.length > 0 && !annotation && isVisible) {
      this.setupInCupAnnotations(chart)
    }
  }

  drawShotChart(element) {
    const hasSecondaryAxis = this.shotDataValue.some(series => series.yAxis === 1)
    const custom = {
      chart: {
        height: 650,
        events: { redraw: e => this.updateInCupVisibility(e.target) }
      },
      series: this.shotDataValue
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
    if (this.shotStagesNormalized.length > 0) {
      this.setupInCupAnnotations(chart)
    }
    return chart
  }

  drawShotStages() {
    this.charts.forEach(chart => {
      if (isObject(chart)) {
        this.shotStagesNormalized.forEach(x => chart.xAxis[0].addPlotLine(x))
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
      series: this.temperatureDataValue
    }

    let options = deepMerge(commonOptions(), custom)
    return Highcharts.chart(element, options)
  }

  applyComparisonOffset(value) {
    if (Object.keys(this.comparisonDataValue).length === 0) return

    this.charts.forEach(chart => {
      if (!isObject(chart)) return

      chart.series.forEach(s => {
        if (!this.comparisonDataValue[s.name]) return

        s.setData(
          this.comparisonDataValue[s.name].map(d => [d[0] + value, d[1]]),
          true,
          false,
          false
        )
      })
    })
  }

  onCompareInput() {
    if (!this.hasCompareRangeTarget) return

    const value = parseInt(this.compareRangeTarget.value)
    this.applyComparisonOffset(value)
  }

  onCompareReset(event) {
    event.preventDefault()
    if (!this.hasCompareRangeTarget) return

    this.compareRangeTarget.value = 0
    this.applyComparisonOffset(0)
  }

  handleColorSchemeChange() {
    if (document.body.classList.contains("system")) {
      this.initializeCharts()
    }
  }
}
