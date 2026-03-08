import { Controller } from "@hotwired/stimulus"
import Highcharts from "highcharts"
import "highcharts/highcharts-more"
import { getColors } from "helpers/shot_chart_helpers"

export default class extends Controller {
  static targets = ["chart"]
  static values = { categories: Array, series: Array, showLegend: Boolean }

  connect() {
    this.handleColorSchemeChange = this.handleColorSchemeChange.bind(this)
    this.drawChart()

    this.colorSchemeMedia = window.matchMedia("(prefers-color-scheme: dark)")
    this.colorSchemeMedia.addEventListener("change", this.handleColorSchemeChange)
  }

  disconnect() {
    this.colorSchemeMedia?.removeEventListener("change", this.handleColorSchemeChange)
    this.chart?.destroy()
  }

  drawChart() {
    const colors = getColors()

    this.chart = Highcharts.chart(this.chartTarget, {
      chart: {
        polar: true,
        type: "line",
        backgroundColor: colors.background,
        animation: false
      },
      accessibility: { enabled: false },
      credits: { enabled: false },
      title: { text: null },
      xAxis: {
        categories: this.categoriesValue,
        tickmarkPlacement: "on",
        lineWidth: 0,
        labels: {
          style: {
            color: colors.label,
            fontSize: "12px"
          }
        },
        gridLineColor: colors.gridLine
      },
      yAxis: {
        min: 0,
        max: 15,
        tickInterval: 5,
        gridLineInterpolation: "polygon",
        lineWidth: 0,
        gridLineColor: colors.gridLine,
        labels: { enabled: false }
      },
      tooltip: { enabled: false },
      legend: {
        enabled: this.showLegendValue,
        itemStyle: { color: colors.legend },
        itemHoverStyle: { color: colors.legendHover }
      },
      plotOptions: {
        series: {
          animation: false,
          pointPlacement: "on",
          enableMouseTracking: false,
          states: {
            hover: {
              enabled: false,
              halo: false
            }
          },
          dataLabels: {
            enabled: true,
            format: "{point.y}",
            style: {
              color: colors.label,
              fontSize: "11px",
              textOutline: "none"
            }
          },
          marker: {
            enabled: true,
            radius: 4
          }
        }
      },
      series: this.seriesValue.map((series, index) => ({
        ...series,
        color: index === 0 ? "#1f3b73" : "#db3e27",
        lineWidth: 2,
        fillOpacity: 0.12
      }))
    })
  }

  handleColorSchemeChange() {
    if (document.body.classList.contains("system")) {
      this.chart?.destroy()
      this.drawChart()
    }
  }
}
