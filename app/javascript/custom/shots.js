import Chart from "chart.js";
require("chartjs-plugin-crosshair")

const chartOptions = {
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
        color: "#888",
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

const classicColors = {
  "espresso_pressure": { title: "Pressure", borderColor: "rgba(5, 199, 147, 1)", backgroundColor: "rgba(5, 199, 147, 0.7)", borderDash: [], fill: true, hidden: false, borderWidth: 3 },
  "espresso_weight": { title: "Weight", borderColor: "rgba(143, 100, 0, 1)", backgroundColor: "rgba(143, 100, 0, 0.7)", borderDash: [], fill: true, hidden: true, borderWidth: 3 },
  "espresso_flow": { title: "Flow", borderColor: "rgba(31, 183, 234, 1)", backgroundColor: "rgba(31, 183, 234, 0.7)", borderDash: [], fill: true, hidden: false, borderWidth: 3 },
  "espresso_flow_weight": { title: "Flow Weight", borderColor: "rgba(17, 138, 178, 1)", backgroundColor: "rgba(17, 138, 178, 0.7)", borderDash: [], fill: true, hidden: false, borderWidth: 3 },
  "espresso_water_dispensed": { title: "Water Dispensed", borderColor: "rgba(31, 183, 234, 1)", backgroundColor: "rgba(31, 183, 234, 0.7)", borderDash: [], fill: true, hidden: false, borderWidth: 3 },
  "espresso_flow_weight_raw": { title: "Flow Weight Raw", borderColor: "rgba(17, 138, 178, 1)", backgroundColor: "rgba(17, 138, 178, 1)", borderDash: [], fill: false, hidden: false, borderWidth: 3 },
  "espresso_flow_goal": { title: "Flow Goal", borderColor: "rgba(9, 72, 93, 1)", backgroundColor: "rgba(9, 72, 93, 1)", borderDash: [5, 5], fill: false, hidden: false, borderWidth: 3 },
  "espresso_resistance": { title: "Resistance", borderColor: "rgba(229, 229, 0, 1)", backgroundColor: "rgba(229, 229, 0, 1)", borderDash: [], fill: false, hidden: false, borderWidth: 3 },
  "espresso_temperature_basket": { title: "Temperature Basket", borderColor: "e73249", backgroundColor: "rgba(240, 86, 122, 0.7)", borderDash: [], fill: false, hidden: false, borderWidth: 3 },
  "espresso_temperature_mix": { title: "Temperature Mix", borderColor: "rgba(206, 18, 62, 1)", backgroundColor: "rgba(206, 18, 62, 0.7)", borderDash: [], fill: false, hidden: false, borderWidth: 3 },
  "espresso_temperature_goal": { title: "Temperature Goal", borderColor: "rgba(150, 13, 45, 1)", backgroundColor: "rgba(150, 13, 45, 0.7)", borderDash: [5, 5], fill: false, hidden: false, borderWidth: 3 },
}

const dsxColors = {
  "espresso_pressure": { title: "Pressure", borderColor: "#18c37e", backgroundColor: "#18c37e", borderDash: [], fill: false, borderWidth: 1 },
  "espresso_weight": { title: "Weight", borderColor: "#a2693d", backgroundColor: "#a2693d", borderDash: [], fill: false, hidden: true, borderWidth: 0 },
  "espresso_flow": { title: "Flow", borderColor: "#4e85f4", backgroundColor: "#4e85f4", borderDash: [], fill: false, borderWidth: 1 },
  "espresso_flow_weight": { title: "Flow Weight", borderColor: "#a2693d", backgroundColor: "#a2693d", borderDash: [5, 5], fill: false, borderWidth: 1 },
  "espresso_pressure_goal": { title: "Pressure Goal", borderColor: "#69fdb3", backgroundColor: "#69fdb3", borderDash: [5, 5], fill: false, borderWidth: 1 },
  "espresso_flow_goal": { title: "Flow Goal", borderColor: "#7aaaff", backgroundColor: "#7aaaff", borderDash: [5, 5], fill: false, borderWidth: 1 },
  "espresso_resistance": { title: "Resistance", borderColor: "#e5e500", backgroundColor: "#e5e500", borderDash: [], fill: false, borderWidth: 1 },
  "espresso_temperature_basket": { title: "Temperature Basket", borderColor: "#e73249", backgroundColor: "#e73249", borderDash: [], fill: false, borderWidth: 1 },
  "espresso_temperature_mix": { title: "Temperature Mix", borderColor: "#ff9900", backgroundColor: "#ff9900", borderDash: [], fill: false, hidden: false, borderWidth: 1 },
  "espresso_temperature_goal": { title: "Temperature Goal", borderColor: "#e73249", backgroundColor: "#e73249", borderDash: [5, 5], fill: false, borderWidth: 1 },
}

var mainChart, temperatureChart;
function chart_from_data(data, skin) {
  var colors;

  if (skin === "dsx") {
    colors = dsxColors
  } else {
    colors = classicColors
  }

  return data.map(function (v) {
    if (v.label in colors) {
      const current = colors[v.label]
      return {
        label: current.title,
        data: v.data,
        title: current.title,
        borderColor: current.borderColor,
        backgroundColor: current.backgroundColor,
        borderDash: current.borderDash,
        fill: current.fill,
        hidden: current.hidden,
        borderWidth: current.borderWidth,
        pointRadius: 0,
      }
    }
  }).filter(e => e);
}

function drawChart(skin) {
  const ctx = document.getElementById("mainChart").getContext("2d");
  mainChart = new Chart(ctx, {
    type: "line",
    data: { datasets: chart_from_data(window.mainData, skin) },
    options: chartOptions
  });
  const tctx = document.getElementById("temperatureChart").getContext("2d");
  temperatureChart = new Chart(tctx, {
    type: "line",
    data: { datasets: chart_from_data(window.temperatureData, skin) },
    options: chartOptions
  });
}

function showChart() {
  if (document.getElementById("checkbox-skin-dsx").checked) {
    document.getElementsByTagName("body")[0].classList.add("black")
    drawChart("dsx")
  } else {
    document.getElementsByTagName("body")[0].classList.remove("black")
    drawChart("classic")
  }
}

document.addEventListener("turbolinks:load", function () {
  showChart()
  if (document.getElementById("skin-picker")) {
    document.getElementById("skin-picker").addEventListener("change", function () {
      mainChart.destroy()
      temperatureChart.destroy()
      showChart()
    })
  }
})
