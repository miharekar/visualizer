import Highcharts from "highcharts"

document.addEventListener("turbo:load", function () {
  const options = {
    accessibility: { enabled: false },
    chart: {
      zoomType: "x",
      height: 500
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
  if (document.getElementById("shot-uploaded-chart")) {
    const chartOptions = { ...options, series: window.uploadedChartData }
    Highcharts.chart("shot-uploaded-chart", chartOptions)
  }

  if (document.getElementById("shot-brewed-chart")) {
    const chartOptions = { ...options, series: window.brewedChartData }
    Highcharts.chart("shot-brewed-chart", chartOptions)
  }

  if (document.getElementById("shot-user-chart")) {
    const chartOptions = { ...options, series: window.userChartData }
    Highcharts.chart("shot-user-chart", chartOptions)
  }
})
