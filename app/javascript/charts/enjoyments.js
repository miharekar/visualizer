import Highcharts from "highcharts"
import { Turbo } from "@hotwired/turbo-rails"

const options = {
  accessibility: { enabled: false },
  animation: false,
  title: false,
  legend: { enabled: false },
  chart: {
    zoomType: "x",
    height: 300
  },
  xAxis: { type: "datetime", },
  title: false,
  yAxis: { title: false },
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

function drawEnjoymentsChart() {
  if (document.getElementById("enjoyments-chart")) {
    const chartOptions = {
      ...options,
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
