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
      accessibility: { enabled: false },
      title: { text: null },
      credits: { enabled: false },
      legend: { enabled: false },
      xAxis: {
        lineWidth: 0,
        tickWidth: 0,
        labels: { style: { color: '#666666' } }
      },
      plotOptions: {
        series: {
          color: '#db3e27',
          states: {
            hover: {
              color: '#af2e1b'
            }
          }
        }
      }
    }

    const mergedOptions = Highcharts.merge(baseOptions, this.chartOptions(data))
    this.chart = Highcharts.chart(this.element, mergedOptions)
  }

  chartOptions(data) {
    throw new Error("You must implement chartOptions()")
  }
}
