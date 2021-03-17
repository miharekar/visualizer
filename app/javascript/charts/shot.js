import Highcharts from "highcharts"

const chartOptions = {
  xAxis: {
    type: "datetime",
    dateTimeLabelFormats: {
      day: "",
      second: "%M:%S",
    },
    crosshair: true
  },
  yAxis: {
    title: false
  },
  tooltip: {
    xDateFormat: "%M:%S.%L",
    shared: true
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
      height: 600,
    },
    title: {
      text: "Shot Chart"
    },
    series: window.shotData
  }
  const options = { ...chartOptions, ...custom }

  Highcharts.chart("shot-chart", options)
}

function drawTemperatureChart() {
  const custom = {
    chart: {
      zoomType: "x",
      height: 400,
    },
    title: {
      text: "Temperature Chart"
    },
    series: window.temperatureData
  }
  const options = { ...chartOptions, ...custom }

  Highcharts.chart("temperature-chart", options)
}

document.addEventListener("turbo:load", function () {
  if (document.getElementById("shot-chart")) {
    drawShotChart()
  }
  if (document.getElementById("temperature-chart")) {
    drawTemperatureChart()
  }
})
