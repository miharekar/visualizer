import ChartController from "controllers/chart_controller"

export default class extends ChartController {
  chartOptions(data) {
    return {
      chart: { type: 'column' },
      tooltip: { pointFormat: '{point.category}: {point.y} shots' },
      plotOptions: {
        column: {
          borderRadius: 3,
          borderWidth: 0,
          dataLabels: {
            enabled: true,
            color: '#666666',
            format: '{point.y}',
            style: {
              fontWeight: 'normal',
              textOutline: 'none'
            }
          }
        }
      }
    }
  }
}
