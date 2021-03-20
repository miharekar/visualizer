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
    hoverPoint.onMouseOut()
    chart.tooltip.hide(hoverPoint)
    chart.xAxis[0].hideCrosshair()
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

let colors
if (window.dark) {
  colors = {
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
  colors = {
    background: "#ffffff",
    label: "#666666",
    gridLine: "#e6e6e6",
    line: "#ccd6eb",
    legend: "#333333",
    legendHover: "#000000",
    legendHidden: "#cccccc"
  }
}

const chartOptions = {
  title: false,
  xAxis: {
    type: "datetime",
    dateTimeLabelFormats: { day: "", second: "%M:%S" },
    events: { setExtremes: syncExtremes },
    crosshair: true,
    plotLines: window.shotStages,
    labels: { style: { color: colors.label } },
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
    xDateFormat: "%M:%S.%L",
    shared: true,
    borderRadius: 10,
    shadow: false,
    borderWidth: 0
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

function drawShotChart() {
  const custom = {
    chart: {
      zoomType: "x",
      height: 650,
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

  const options = { ...chartOptions, ...legendOptions, ...custom }

  Highcharts.chart("shot-chart", options)
}

function drawTemperatureChart() {
  const custom = {
    chart: {
      zoomType: "x",
      height: 400,
      backgroundColor: colors.background
    },
    series: window.temperatureData
  }
  const options = { ...chartOptions, ...custom }

  Highcharts.chart("temperature-chart", options)
}

document.addEventListener("turbo:load", function () {
  Highcharts.charts.forEach(function (chart) {
    if (isObject(chart)) { chart.destroy() }
  })

  const shotChart = document.getElementById("shot-chart")
  const temperatureChart = document.getElementById("temperature-chart")
  if (shotChart) {
    drawShotChart()
    syncMouseEvents(shotChart)
  }
  if (temperatureChart) {
    drawTemperatureChart()
    syncMouseEvents(temperatureChart)
  }
})
