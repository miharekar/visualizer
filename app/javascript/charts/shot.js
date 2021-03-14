var Highcharts = require('highcharts');
//require('highcharts/modules/boost')(Highcharts);

function drawChart() {
  const chart = Highcharts.chart('container', {
    chart: {
      zoomType: 'x',
      animation: false,
      height: 600
    },
    title: false,
    xAxis: {
      type: 'datetime'
    },
    yAxis: {
      title: false
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
    series: window.highchartsData
  });
}

document.addEventListener("turbo:load", function (xhr) {
  if (document.getElementById("container")) {
    drawChart()
  }
})
