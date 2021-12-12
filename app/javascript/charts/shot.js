import Highcharts from "highcharts"

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
  if (window.dark) {
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
    title: false,
    xAxis: {
      type: "datetime",
      events: { setExtremes: syncExtremes },
      crosshair: true,
      labels: {
        style: { color: colors.label },
        formatter: function () {
          if (this.value < 0) {
            return "-" + Highcharts.dateFormat('%M:%S', -this.value)
          } else {
            return Highcharts.dateFormat('%M:%S', this.value)
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
      shared: true,
      borderRadius: 10,
      shadow: false,
      borderWidth: 0,
      formatter: function (tooltip) {
        let s
        if (this.x < 0) {
          s = ["-" + Highcharts.dateFormat('%M:%S.%L', -this.x) + "<br>"]
        } else {
          s = [Highcharts.dateFormat('%M:%S.%L', this.x) + "<br>"]
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

function drawShotChart() {
  const colors = getColors()

  const custom = {
    chart: {
      zoomType: "x",
      height: window.chartHeight,
      backgroundColor: colors.background
    },
    series: window.shotData
  }

  let legendOptions = {}
  if (window.hideLegend) {
    legendOptions = {
      legend: {
        enabled: false
      }
    }
  }

  let options = { ...commonOptions(), ...legendOptions, ...custom }
  options.xAxis.plotLines = window.shotStages

  Highcharts.chart("shot-chart", options)
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
    const value = this.value * window.multiplier
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
