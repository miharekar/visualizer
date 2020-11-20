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
