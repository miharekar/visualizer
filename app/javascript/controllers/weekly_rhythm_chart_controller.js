import ChartController from "controllers/chart_controller"

export default class extends ChartController {
  chartOptions(data) {
    return {
      chart: {
        type: 'column',
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
        visible: false,
        min: 0
      },
      tooltip: {
        headerFormat: '',
        pointFormat: '{point.category}: {point.y} shots'
      },
      plotOptions: {
        column: {
          borderRadius: 3,
          dataLabels: {
            enabled: true,
            color: '#666666',
            format: '{point.y}',
            style: {
              fontSize: '12px',
              fontWeight: 'normal'
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
