import Highcharts from "highcharts"

function isObject(obj) {
  return obj && typeof obj === 'object'
}

Highcharts.wrap(Highcharts.Chart.prototype, 'zoom', function (proceed) {
  proceed.apply(this, [].slice.call(arguments, 1))

  if (!isObject(this.resetZoomButton)) {
    Highcharts.charts.forEach(function (chart) {
      if (isObject(chart.resetZoomButton)) {
        chart.resetZoomButton.destroy()
        chart.resetZoomButton = undefined
      }
    })
  }
})

function handleMouse(e) {
  const currentChart = this
  Highcharts.charts.forEach(function (chart) {
    if (currentChart === chart.renderTo) return

    const event = chart.pointer.normalize(e)
    let point
    for (let j = 0; j < chart.series.length && !point; ++j) {
      point = chart.series[j].searchPoint(event, true)
    }
    if (!point) return

    if (e.type === "mousemove") {
      point.plotY = chart.chartHeight / 2
      point.onMouseOver()
      chart.xAxis[0].drawCrosshair(event, point)
    } else {
      point.onMouseOut()
      chart.tooltip.hide(point)
      chart.xAxis[0].hideCrosshair()
    }
  })
}

function syncExtremes(e) {
  var thisChart = this.chart

  if (e.trigger !== "syncExtremes") {
    Highcharts.charts.forEach(function (chart) {
      if (chart === thisChart) return

      if (chart.xAxis[0].setExtremes) {
        chart.xAxis[0].setExtremes(e.min, e.max, undefined, false, { trigger: "syncExtremes" })
        if (!isObject(chart.resetZoomButton)) {
          chart.showResetZoom()
        }
      }

    })
  }
}

const chartOptions = {
  xAxis: {
    type: "datetime",
    dateTimeLabelFormats: {
      day: "",
      second: "%M:%S",
    },
    events: {
      setExtremes: syncExtremes
    },
    crosshair: true,
    plotLines: window.shotStages
  },
  title: false,
  yAxis: {
    title: false
  },
  tooltip: {
    xDateFormat: "%M:%S.%L",
    shared: true,
    borderRadius: 10,
    shadow: false,
    borderWidth: 0
  },
  plotOptions: {
    series: {
      animation: false,
      marker: {
        enabled: false,
        states: {
          hover: {
            enabled: false
          }
        }
      },
      states: {
        hover: {
          enabled: false
        },
        inactive: {
          enabled: false
        }
      }
    }
  },
  credits: {
    enabled: false
  },
}

function drawShotChart() {
  const custom = {
    chart: {
      zoomType: "x",
      height: 650,
      backgroundColor: window.dark ? "#000" : "#fff"
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
      backgroundColor: window.dark ? "#000" : "#fff"
    },
    series: window.temperatureData
  }
  const options = { ...chartOptions, ...custom }

  Highcharts.chart("temperature-chart", options)
}

document.addEventListener("turbo:load", function () {
  const shotChart = document.getElementById("shot-chart")
  const temperatureChart = document.getElementById("temperature-chart")
  if (shotChart) {
    drawShotChart()
    shotChart.addEventListener("mousemove", handleMouse)
    shotChart.addEventListener("mouseleave", handleMouse)
  }
  if (temperatureChart) {
    drawTemperatureChart()
    temperatureChart.addEventListener("mousemove", handleMouse)
    temperatureChart.addEventListener("mouseleave", handleMouse)
  }
})
