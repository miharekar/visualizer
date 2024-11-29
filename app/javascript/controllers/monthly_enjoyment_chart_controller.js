import ChartController from "controllers/chart_controller"

export default class extends ChartController {
  chartOptions(data) {
    return {
      chart: {
        type: 'spline',
      },
      xAxis: {
        categories: data.map(d => d[0]),
        labels: {
          formatter: function () {
            return this.value[0]
          }
        }
      },
      yAxis: {
        title: { text: null },
        gridLineWidth: 1,
        labels: { enabled: false }
      },
      tooltip: {
        headerFormat: '',
        pointFormat: '{point.category}: {point.y}'
      },
      plotOptions: {
        spline: {
          marker: {
            enabled: true,
            radius: 4,
            lineWidth: 1,
            lineColor: '#db3e27'
          },
          states: {
            hover: {
              lineWidth: 2
            }
          }
        }
      },
      series: [{
        data: data.map(d => d[1])
      }]
    }
  }
}
