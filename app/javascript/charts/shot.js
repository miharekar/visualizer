import Highcharts from "highcharts"

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

function isObject(obj) {
  return obj && typeof obj === 'object'
}

function mostCommon(arr) {
  return arr.sort((a, b) =>
    arr.filter(v => v === a).length
    - arr.filter(v => v === b).length
  ).pop();
}

function handleMouse(e) {
  const thisChart = this

  Highcharts.charts.forEach(function (chart) {
    if (thisChart === chart.renderTo) return

    e = chart.pointer.normalize(e)
    let points = [];
    chart.series.forEach(function (p) {
      points.push(p.searchPoint(e, true))
    })
    if (!points.length) return

    let visiblePoints = []
    let xValues = []
    points.forEach(function (p) {
      if (p && p.series.visible) {
        visiblePoints.push(p)
        xValues.push(p.clientX)
      }
    })
    if (!visiblePoints.length) return

    const x = mostCommon(xValues)
    let selectedPoints = []
    visiblePoints.forEach(function (p) {
      if (p.clientX === x) {
        selectedPoints.push(p)
      }
    })
    if (!selectedPoints.length) return

    chart.tooltip.refresh(selectedPoints)
    chart.xAxis[0].drawCrosshair(e, selectedPoints[0])
  })
}

function syncExtremes(e) {
  const thisChart = this.chart

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
