import Highcharts from "highcharts"
import "highcharts-annotations"

Highcharts.wrap(Highcharts.Chart.prototype, "zoom", function (proceed) {
  proceed.apply(this, [].slice.call(arguments, 1))

  if (!isObject(this.resetZoomButton)) {
    Highcharts.charts.forEach(function (chart) {
      if (isObject(chart) && isObject(chart.resetZoomButton)) {
        chart.resetZoomButton.destroy()
        chart.resetZoomButton = undefined
      }
    })
  }
})

function isObject(obj) {
  return obj && typeof obj === "object"
}

function syncMouseEvents(element) {
  element.addEventListener("mousemove", syncMouse)
  element.addEventListener("touchstart", syncMouse)
  element.addEventListener("touchmove", syncMouse)
  element.addEventListener("mouseleave", mouseLeave)
}

function getHoverPoint(chart, e) {
  e = chart.pointer.normalize(e)
  return chart.pointer.findNearestKDPoint(chart.series, true, e)
}

function syncMouse(e) {
  const thisChart = this

  Highcharts.charts.forEach(function (chart) {
    if (!isObject(chart) || thisChart === chart.renderTo) return

    const hoverPoint = getHoverPoint(chart, e)
    let hoverPoints = []
    if (hoverPoint) {
      chart.series.forEach(function (s) {
        if (!s.visible) return

        const point = Highcharts.find(s.points, function (p) {
          return p.x === hoverPoint.x && !p.isNull
        })

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

function mouseLeave(e) {
  Highcharts.charts.forEach(function (chart) {
    if (!isObject(chart)) return

    const hoverPoint = getHoverPoint(chart, e)

    if (hoverPoint) {
      hoverPoint.onMouseOut()
      chart.tooltip.hide(hoverPoint)
      chart.xAxis[0].hideCrosshair()
    }
  })
}

function syncExtremes(e) {
  const thisChart = this.chart

  if (e.trigger !== "syncExtremes") {
    Highcharts.charts.forEach(function (chart) {
      if (!isObject(chart) || chart === thisChart) return

      if (chart.xAxis[0].setExtremes) {
        chart.xAxis[0].setExtremes(e.min, e.max, undefined, false, { trigger: "syncExtremes" })
        if (!isObject(chart.resetZoomButton)) {
          chart.showResetZoom()
        }
      }
    })
  }
}

function getColors() {
  if (document.body.classList.contains("dark")) {
    return {
      background: "#000000",
      label: "#999999",
      gridLine: "#191919",
      line: "#332914",
      legend: "#cccccc",
      legendHover: "#ffffff",
      legendHidden: "#333333"
    }
  }
  else {
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

function commonOptions() {
  const colors = getColors()
  return {
    accessibility: { enabled: false },
    animation: false,
    title: false,
    xAxis: {
      type: "datetime",
      events: { setExtremes: syncExtremes },
      crosshair: true,
      labels: {
        style: { color: colors.label },
        formatter: function () {
          if (this.value < 0) {
            return "-" + Highcharts.dateFormat("%M:%S", -this.value)
          } else {
            return Highcharts.dateFormat("%M:%S", this.value)
          }
        }
      },
      gridLineColor: colors.gridLine,
      lineColor: colors.line,
      tickColor: colors.line,
    },
    yAxis: {
      title: false,
      labels: { style: { color: colors.label } },
      gridLineColor: colors.gridLine,
      lineColor: colors.line,
      tickColor: colors.line,
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
          s = ["-" + Highcharts.dateFormat("%M:%S.%L", -this.x) + "<br>"]
        } else {
          s = [Highcharts.dateFormat("%M:%S.%L", this.x) + "<br>"]
        }

        return s.concat(tooltip.bodyFormatter(this.points))
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
          states: {
            hover: { enabled: false }
          }
        },
        states: {
          hover: { enabled: false },
          inactive: { enabled: false }
        }
      }
    },
    credits: {
      enabled: false
    }
  }
}

function extractStages(field, timings) {
  for (let i = 0; i < window.shotData.length; i++) {
    let data = window.shotData[i];
    if (data.name == field) {
      return data.data.filter((x) => timings.includes(x[0])).map((x) => x[1])
    }
  }

  // If the series is not present, assume all 0
  return timings.map(_ => 0)
}

function setupInCupAnnotations(chart) {
  const weightColor = chart.series.filter(x => (x.name == "Weight Flow"))[0].color
  const timings = shotStages.map(x => x.value)
  const weightFlow = extractStages("Weight Flow", timings)
  const weight = extractStages("Weight", timings)

  let labels = []
  timings.forEach((timing, index) => {
    const inCup = weight[index]
    if (inCup > 0) {
      labels.push({
        text: `${inCup}g`,
        point: { "x": timing, "y": weightFlow[index], "xAxis": 0, "yAxis": 0 },
        y: -30,
        x: -30,
        allowOverlap: true,
        style: { color: weightColor },
        borderColor: weightColor,
      })
    }
  })

  let annotation = {
    draggable: false,
    labels: labels,
    labelOptions: { shape: "connector" }
  }

  chart.inCupAnnotation = chart.addAnnotation(annotation)
}

function updateInCupVisibility(chart) {
  const weightFlowSeries = chart.series.filter(x => (x.name == "Weight Flow" && x.visible))
  const isVisible = weightFlowSeries.length > 0
  const annotation = chart.inCupAnnotation

  // Highcharts does not allow changing the visibility of a chart, so it must be removed and recreated
  // Doing so causes a redraw within the redraw, but we only apply changes when the visibility toggles
  if (annotation && !isVisible) {
    chart.removeAnnotation(annotation)
    chart.inCupAnnotation = null
  } else if (!annotation && isVisible) {
    setupInCupAnnotations(chart)
  }
}

function drawShotChart() {
  const colors = getColors()

  const custom = {
    chart: {
      zoomType: "x",
      height: 650,
      backgroundColor: colors.background,
      events: {
        redraw: x => updateInCupVisibility(x.target)
      }
    },
    series: window.shotData
  }

  let options = { ...commonOptions(), ...custom }
  options.xAxis.plotLines = window.shotStages

  let chart = Highcharts.chart("shot-chart", options)
  setupInCupAnnotations(chart)
}

function drawTemperatureChart() {
  const colors = getColors()

  const custom = {
    chart: {
      zoomType: "x",
      height: 400,
      backgroundColor: colors.background
    },
    series: window.temperatureData
  }

  let options = { ...commonOptions(), ...custom }
  options.xAxis.plotLines = window.shotStages

  Highcharts.chart("temperature-chart", options)
}

function comparisonAdjust(range) {
  range.addEventListener("input", function () {
    const value = parseInt(this.value)
    Highcharts.charts.forEach(function (chart) {
      if (isObject(chart)) {
        chart.series.forEach(function (s) {
          if (window.comparisonData[s.name]) {
            s.setData(window.comparisonData[s.name].map(function (d) {
              return [d[0] + value, d[1]]
            }), true, false, false)
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

document.addEventListener("turbo:load", function () {
  Highcharts.charts.forEach(function (chart) {
    if (isObject(chart)) { chart.destroy() }
  })

  const shotChart = document.getElementById("shot-chart")
  const temperatureChart = document.getElementById("temperature-chart")
  const range = document.getElementById("compare-range")
  if (shotChart) {
    drawShotChart()
    syncMouseEvents(shotChart)
  }
  if (temperatureChart) {
    drawTemperatureChart()
    syncMouseEvents(temperatureChart)
  }
  if (range) {
    comparisonAdjust(range)
  }
})
