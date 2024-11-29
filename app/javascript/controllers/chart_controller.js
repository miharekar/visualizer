import { Controller } from "@hotwired/stimulus"
import Highcharts from "highcharts"

export default class extends Controller {
  connect() {
    this.drawChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  drawChart() {
    const data = JSON.parse(this.element.dataset.chartData)
    const baseOptions = {
      chart: { backgroundColor: 'transparent' },
      accessibility: { enabled: false },
      title: { text: null },
      credits: { enabled: false },
      legend: { enabled: false },
      yAxis: { visible: false, min: 0 },
      xAxis: {
        lineWidth: 0,
        tickWidth: 0,
        labels: { style: { color: '#666666' } },
        categories: data.map(d => d[0]),
        labels: { formatter: function () { return this.value[0] } }
      },
      tooltip: { headerFormat: '' },
      plotOptions: {
        series: {
          color: '#db3e27',
          states: { hover: { color: '#af2e1b' } }
        }
      },
      series: [{
        data: data.map(d => d[1])
      }]
    }

    const mergedOptions = Highcharts.merge(baseOptions, this.chartOptions(data))
    this.chart = Highcharts.chart(this.element, mergedOptions)
  }

  chartOptions(data) {
    throw new Error("You must implement chartOptions()")
  }
}
