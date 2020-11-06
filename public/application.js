var timeFormat = 'HH:mm:ss';
var options = {
  scales: {
    xAxes: [{
      type: 'time',
      time: {
        displayFormats: { second: 'HH:mm:ss' }
      },
      distribution: 'series',
      offset: true,
      ticks: {
        source: 'data',
        autoSkip: true,
        autoSkipPadding: 75,
        maxRotation: 0,
        sampleSize: 100
      }
    }]
  },
  plugins: {
    zoom: {
      pan: {
        enabled: true,
        mode: 'x'
      },
      zoom: {
        enabled: true,
        mode: 'x'
      }
    }
  },
  tooltips: {
    intersect: false,
    mode: 'index',
    callbacks: {
      label: function (tooltipItem, myData) {
        var label = myData.datasets[tooltipItem.datasetIndex].label || '';
        if (label) {
          label += ': ';
        }
        label += parseFloat(tooltipItem.value).toFixed(2);
        return label;
      }
    }
  }
}
