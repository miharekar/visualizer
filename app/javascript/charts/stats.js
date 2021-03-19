import Highcharts from "highcharts"

document.addEventListener("turbo:load", function () {
  if (document.getElementById("shot-counts-chart")) {
    const options = {
      series: window.shotChartData,
      chart: {
        zoomType: "x",
        height: 600
      },
      xAxis: {
        type: "datetime",
      },
      title: false,
      yAxis: {
        title: false
      },
      credits: {
        enabled: false
      },
    }

    Highcharts.chart("shot-counts-chart", options)
  }
})
