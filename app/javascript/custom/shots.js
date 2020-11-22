import Chart from "chart.js";
require("chartjs-plugin-crosshair")

window.chartOptions = {
  scales: {
    xAxes: [{
      type: "time",
      time: {
        displayFormats: {
          second: "ss.SS[s]"
        },
        tooltipFormat: "ss.SS[s]",
      },
      distribution: "series",
      offset: true,
      ticks: {
        source: "data",
        autoSkip: true,
        autoSkipPadding: 50,
        maxRotation: 0
      }
    }]
  },
  plugins: {
    crosshair: {
      line: {
        color: '#000',
        dashPattern: [5, 5]
      },
    },
  },
  tooltips: {
    intersect: false,
    mode: "index",
    callbacks: {
      label: function (tooltipItem, myData) {
        var label = myData.datasets[tooltipItem.datasetIndex].label || "";
        if (label) {
          label += ": ";
        }
        label += parseFloat(tooltipItem.value).toFixed(2);
        return label;
      }
    }
  }
}

const chartColors = {
  "espresso_pressure": { title: "Pressure", borderColor: "rgba(5, 199, 147, 1)", backgroundColor: "rgba(5, 199, 147, 0.7)", borderDash: [], fill: true, hidden: false },
  "espresso_weight": { title: "Weight", borderColor: "rgba(143, 100, 0, 1)", backgroundColor: "rgba(143, 100, 0, 0.7)", borderDash: [], fill: true, hidden: true },
  "espresso_flow": { title: "Flow", borderColor: "rgba(31, 183, 234, 1)", backgroundColor: "rgba(31, 183, 234, 0.7)", borderDash: [], fill: true, hidden: false },
  "espresso_flow_weight": { title: "Flow Weight", borderColor: "rgba(17, 138, 178, 1)", backgroundColor: "rgba(17, 138, 178, 0.7)", borderDash: [], fill: true, hidden: false },
  "espresso_temperature_basket": { title: "Temperature Basket", borderColor: "rgba(240, 86, 122, 1)", backgroundColor: "rgba(240, 86, 122, 0.7)", borderDash: [], fill: false, hidden: false },
  "espresso_temperature_mix": { title: "Temperature Mix", borderColor: "rgba(206, 18, 62, 1)", backgroundColor: "rgba(206, 18, 62, 0.7)", borderDash: [], fill: false, hidden: false },
  "espresso_water_dispensed": { title: "Water Dispensed", borderColor: "rgba(31, 183, 234, 1)", backgroundColor: "rgba(31, 183, 234, 0.7)", borderDash: [], fill: true, hidden: false },
  "espresso_temperature_goal": { title: "Temperature Goal", borderColor: "rgba(150, 13, 45, 1)", backgroundColor: "rgba(150, 13, 45, 0.7)", borderDash: [5, 5], fill: false, hidden: false },
  "espresso_flow_weight_raw": { title: "Flow Weight Raw", borderColor: "rgba(17, 138, 178, 1)", backgroundColor: "rgba(17, 138, 178, 1)", borderDash: [], fill: false, hidden: false },
  "espresso_pressure_goal": { title: "Pressure Goal", borderColor: "rgba(3, 99, 74, 1)", backgroundColor: "rgba(3, 99, 74, 1)", borderDash: [5, 5], fill: false, hidden: false },
  "espresso_flow_goal": { title: "Flow Goal", borderColor: "rgba(9, 72, 93, 1)", backgroundColor: "rgba(9, 72, 93, 1)", borderDash: [5, 5], fill: false, hidden: false },
  "espresso_resistance": { title: "Resistance", borderColor: "rgba(229, 229, 0, 1)", backgroundColor: "rgba(229, 229, 0, 1)", borderDash: [], fill: false, hidden: false }
}

window.chart_from_data = function (data) {
  return data.map(function (v) {
    return {
      label: chartColors[v.label].title,
      data: v.data,
      title: chartColors[v.label].title,
      borderColor: chartColors[v.label].borderColor,
      backgroundColor: chartColors[v.label].backgroundColor,
      borderDash: chartColors[v.label].borderDash,
      fill: chartColors[v.label].fill,
      hidden: chartColors[v.label].hidden,
      pointRadius: 0,
    }
  })
}
