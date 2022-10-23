import Highcharts from "highcharts"
import { Turbo } from "@hotwired/turbo-rails"

function isDark() {
  if (document.body.classList.contains("system")) {
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
  } else {
    return document.body.classList.contains("dark")
  }
}

function getColors() {
  if (isDark()) {
    return {
      background: "#000000",
      gridLine: "#191919"
    }
  }
  else {
    return {
      background: "#ffffff",
      gridLine: "#e6e6e6"
    }
  }
}

function commonOptions() {
  const colors = getColors()
  return {
    accessibility: { enabled: false },
    animation: false,
    title: false,
    legend: { enabled: false },
    chart: {
      zoomType: "x",
      height: 300,
      backgroundColor: colors.background
    },
    xAxis: {
      type: "datetime",
      gridLineColor: colors.gridLine,
      lineColor: colors.line,
      tickColor: colors.line,
    },
    title: false,
    yAxis: {
      title: false,
      max: 100,
      gridLineColor: colors.gridLine
    },
    credits: { enabled: false },
    tooltip: {
      animation: false,
      formatter: function () {
        return this.point.title
      }
    },
    plotOptions: {
      series: {
        cursor: "pointer",
        point: {
          events: {
            click: function () {
              Turbo.visit(this.url)
            }
          }
        },
        states: { hover: { enabled: false } },
        animation: false,
        marker: {
          enabled: true,
          radius: 5
        },
        lineWidth: 0
      }
    },
  }
}

function drawEnjoymentsChart() {
  if (document.getElementById("enjoyments-chart")) {
    const chartOptions = {
      ...commonOptions(),
      series: [{
        name: "Enjoyments throughout time",
        data: window.enjoymentsData,
        lineWidth: 0
      }]
    }
    Highcharts.chart("enjoyments-chart", chartOptions)
  }
}

document.addEventListener("turbo:frame-load", drawEnjoymentsChart)
document.addEventListener("turbo:load", drawEnjoymentsChart)

window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", function () {
  if (document.body.classList.contains("system")) {
    drawEnjoymentsChart()
  }
})
