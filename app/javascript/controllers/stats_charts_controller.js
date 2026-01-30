import { Controller } from "@hotwired/stimulus"
import Highcharts from "highcharts"

export default class extends Controller {
  static targets = ["uploadedChart", "userChart"]
  static values = {
    uploadedChartData: Array,
    userChartData: Array
  }

  connect() {
    this.charts = []
    this.initializeCharts()
  }

  disconnect() {
    this.charts.forEach(chart => chart.destroy())
    this.charts = []
  }

  initializeCharts() {
    const options = {
      accessibility: { enabled: false },
      chart: {
        zoomType: "x",
        height: 500
      },
      xAxis: {
        type: "datetime"
      },
      title: false,
      yAxis: {
        title: false
      },
      credits: {
        enabled: false
      }
    }

    if (this.hasUploadedChartTarget && this.uploadedChartDataValue.length > 0) {
      const chart = Highcharts.chart(this.uploadedChartTarget, {
        ...options,
        series: this.uploadedChartDataValue
      })
      this.charts.push(chart)
    }

    if (this.hasUserChartTarget && this.userChartDataValue.length > 0) {
      const chart = Highcharts.chart(this.userChartTarget, {
        ...options,
        series: this.userChartDataValue
      })
      this.charts.push(chart)
    }
  }
}
