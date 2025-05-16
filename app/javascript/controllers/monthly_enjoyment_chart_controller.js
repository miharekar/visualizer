import ChartController from "controllers/chart_controller"

export default class extends ChartController {
  chartOptions(data) {
    return {
      chart: { type: "spline" },
      tooltip: { pointFormat: "{point.category}: {point.y}" },
      plotOptions: {
        spline: {
          marker: {
            enabled: true,
            radius: 4,
            lineWidth: 1,
            lineColor: "#db3e27"
          },
          states: { hover: { lineWidth: 3 } }
        }
      }
    }
  }
}
