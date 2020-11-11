var options = {
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
    zoom: {
      pan: {
        enabled: true,
        mode: "x"
      },
      zoom: {
        enabled: true,
        mode: "x"
      }
    }
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
