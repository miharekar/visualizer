import Highcharts from "highcharts"

const chartOptions = {
  xAxis: {
    type: "datetime",
    dateTimeLabelFormats: {
      day: "",
      second: "%M:%S",
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
  const options = { ...chartOptions, ...custom }

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
  if (document.getElementById("shot-chart")) {
    drawShotChart()
  }
  if (document.getElementById("temperature-chart")) {
    drawTemperatureChart()
  }
})
