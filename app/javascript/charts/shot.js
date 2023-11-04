import Highcharts from "highcharts";
import "highcharts-annotations";

Highcharts.wrap(Highcharts.Chart.prototype, "zoom", function (proceed) {
  proceed.apply(this, [].slice.call(arguments, 1));

  if (!isObject(this.resetZoomButton)) {
    Highcharts.charts.forEach(function (chart) {
      if (isObject(chart) && isObject(chart.resetZoomButton)) {
        chart.resetZoomButton.destroy();
        chart.resetZoomButton = undefined;
      }
    });
  }
});

function isObject(obj) {
  return obj && typeof obj === "object";
}

function syncMouseEvents(element) {
  element.addEventListener("mousemove", syncMouse);
  element.addEventListener("touchstart", syncMouse);
  element.addEventListener("touchmove", syncMouse);
  element.addEventListener("mouseleave", mouseLeave);
}

function getHoverPoint(chart, e) {
  e = chart.pointer.normalize(e);
  return chart.pointer.findNearestKDPoint(chart.series, true, e);
}

function syncMouse(e) {
  const thisChart = this;

  Highcharts.charts.forEach(function (chart) {
    if (!isObject(chart) || thisChart === chart.renderTo) return;

    const hoverPoint = getHoverPoint(chart, e);
    let hoverPoints = [];
    if (hoverPoint) {
      chart.series.forEach(function (s) {
        if (!s.visible) return;

        const point = Highcharts.find(s.points, function (p) {
          return p.x === hoverPoint.x && !p.isNull;
        });

        if (isObject(point)) {
          hoverPoints.push(point);
        }
      });
    }

    if (hoverPoints.length) {
      chart.tooltip.refresh(hoverPoints);
      chart.xAxis[0].drawCrosshair(e, hoverPoints[0]);
    }
  });
}

function mouseLeave(e) {
  Highcharts.charts.forEach(function (chart) {
    if (!isObject(chart)) return;

    const hoverPoint = getHoverPoint(chart, e);

    if (hoverPoint) {
      hoverPoint.onMouseOut();
      chart.tooltip.hide(hoverPoint);
      chart.xAxis[0].hideCrosshair();
    }
  });
}

function syncExtremes(e) {
  const thisChart = this.chart;

  if (e.trigger !== "syncExtremes") {
    Highcharts.charts.forEach(function (chart) {
      if (!isObject(chart) || chart === thisChart) return;

      if (chart.xAxis[0].setExtremes) {
        chart.xAxis[0].setExtremes(e.min, e.max, undefined, false, { trigger: "syncExtremes" });
        if (!isObject(chart.resetZoomButton)) {
          chart.showResetZoom();
        }
      }
    });
  }
}

function isDark() {
  if (document.body.classList.contains("system")) {
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
  } else {
    return document.body.classList.contains("dark");
  }
}

function getColors() {
  if (isDark()) {
    return {
      background: "#000000",
      label: "#999999",
      gridLine: "#191919",
      line: "#332914",
      legend: "#cccccc",
      legendHover: "#ffffff",
      legendHidden: "#333333",
    };
  } else {
    return {
      background: "#ffffff",
      label: "#666666",
      gridLine: "#e6e6e6",
      line: "#ccd6eb",
      legend: "#333333",
      legendHover: "#000000",
      legendHidden: "#cccccc",
    };
  }
}

function commonOptions() {
  const colors = getColors();
  return {
    accessibility: { enabled: false },
    animation: false,
    title: false,
    xAxis: {
      type: "datetime",
      events: { setExtremes: syncExtremes },
      crosshair: true,
      labels: {
        style: { color: colors.label },
        formatter: function () {
          if (this.value < 0) {
            return "-" + Highcharts.dateFormat("%M:%S", -this.value);
          } else {
            return Highcharts.dateFormat("%M:%S", this.value);
          }
        },
      },
      gridLineColor: colors.gridLine,
      lineColor: colors.line,
      tickColor: colors.line,
    },
    yAxis: {
      title: false,
      labels: { style: { color: colors.label } },
      gridLineColor: colors.gridLine,
      lineColor: colors.line,
      tickColor: colors.line,
    },
    tooltip: {
      animation: false,
      shared: true,
      borderRadius: 10,
      shadow: false,
      borderWidth: 0,
      formatter: function (tooltip) {
        let s;
        if (this.x < 0) {
          s = ["-" + Highcharts.dateFormat("%M:%S.%L", -this.x) + "<br>"];
        } else {
          s = [Highcharts.dateFormat("%M:%S.%L", this.x) + "<br>"];
        }

        return s.concat(tooltip.bodyFormatter(this.points));
      },
    },
    legend: {
      itemStyle: { color: colors.legend },
      itemHoverStyle: { color: colors.legendHover },
      itemHiddenStyle: { color: colors.legendHidden },
    },
    plotOptions: {
      series: {
        animation: false,
        marker: {
          enabled: false,
          states: {
            hover: { enabled: false },
          },
        },
        states: {
          hover: { enabled: false },
          inactive: { enabled: false },
        },
      },
    },
    credits: { enabled: false },
  };
}

function extractStages(field, timings) {
  for (let i = 0; i < window.shotData.length; i++) {
    let fieldData = window.shotData[i];
    if (fieldData.name == field) {
      return timings.map((time) => new Map(fieldData.data).get(time));
    }
  }

  // If the series is not present, assume all 0
  return timings.map((_) => 0);
}

function setupInCupAnnotations(chart) {
  const weightColor = chart.series.filter((x) => x.name == "Weight Flow")[0].color;
  const timings = shotStages.map((x) => x.value);
  const weightFlow = extractStages("Weight Flow", timings);
  const weight = extractStages("Weight", timings);

  let labels = [];
  timings.forEach((timing, index) => {
    const inCup = weight[index];
    if (inCup > 0) {
      labels.push({
        text: `${inCup}g`,
        point: { x: timing, y: weightFlow[index], xAxis: 0, yAxis: 0 },
        y: -30,
        x: -30,
        allowOverlap: true,
        style: { color: weightColor },
        borderColor: weightColor,
      });
    }
  });

  chart.inCupAnnotation = chart.addAnnotation({
    draggable: false,
    labels: labels,
    labelOptions: { shape: "connector" },
  });

  chart.renderer
    .text(
      '<button id="remove-annotations" class="inline-flex px-2 py-1 text-xs font-medium bg-white border rounded cursor-pointer highcharts-no-tooltip border-neutral-300 dark:border-neutral-600 shadow-sm text-neutral-700 dark:bg-neutral-800 dark:text-neutral-300 hover:bg-neutral-50 dark:hover:bg-neutral-900">Hide annotations</span>',
      50,
      35,
      true
    )
    .attr({ zIndex: 3 })
    .add();
  chart.annotationVisible = true;
  document.getElementById("remove-annotations").addEventListener("click", function () {
    if (chart.annotationVisible) {
      destroyShotStages();
      chart.annotations[0].graphic.hide();
      chart.annotationVisible = false;
      this.innerHTML = "Show annotations";
    } else {
      drawShotStages();
      chart.annotations[0].graphic.show();
      chart.annotationVisible = true;
      this.innerHTML = "Hide annotations";
    }
  });
}

function updateInCupVisibility(chart) {
  const weightFlowSeries = chart.series.filter((x) => x.name == "Weight Flow" && x.visible);
  const isVisible = weightFlowSeries.length > 0;
  const annotation = chart.inCupAnnotation;

  // Highcharts does not allow changing the visibility of a chart, so it must be removed and recreated
  // Doing so causes a redraw within the redraw, but we only apply changes when the visibility toggles
  if (annotation && !isVisible) {
    chart.removeAnnotation(annotation);
    chart.inCupAnnotation = null;
  } else if (window.shotStages?.length > 0 && !annotation && isVisible) {
    setupInCupAnnotations(chart);
  }
}

function drawShotChart() {
  const colors = getColors();

  const custom = {
    chart: {
      zoomType: "x",
      height: 650,
      backgroundColor: colors.background,
      events: {
        redraw: (x) => updateInCupVisibility(x.target),
      },
    },
    series: window.shotData,
  };

  let options = { ...commonOptions(), ...custom };

  let chart = Highcharts.chart("shot-chart", options);
  if (window.shotStages?.length > 0) {
    setupInCupAnnotations(chart);
  }
}

function destroyShotStages() {
  Highcharts.charts.forEach(function (chart) {
    if (isObject(chart)) {
      while (chart.xAxis[0].plotLinesAndBands.length > 0) {
        chart.xAxis[0].plotLinesAndBands.forEach(function (plotLine) {
          chart.xAxis[0].removePlotLine(plotLine.id);
        });
      }
    }
  });
}

function drawShotStages() {
  Highcharts.charts.forEach(function (chart) {
    if (isObject(chart)) {
      window.shotStages.forEach((x) => chart.xAxis[0].addPlotLine(x));
    }
  });
}

function drawTemperatureChart() {
  const colors = getColors();

  const custom = {
    chart: {
      zoomType: "x",
      height: 400,
      backgroundColor: colors.background,
    },
    series: window.temperatureData,
  };

  let options = { ...commonOptions(), ...custom };

  Highcharts.chart("temperature-chart", options);
}

function comparisonAdjust(range) {
  range.addEventListener("input", function () {
    const value = parseInt(this.value);
    Highcharts.charts.forEach(function (chart) {
      if (isObject(chart)) {
        chart.series.forEach(function (s) {
          if (window.comparisonData[s.name]) {
            s.setData(
              window.comparisonData[s.name].map(function (d) {
                return [d[0] + value, d[1]];
              }),
              true,
              false,
              false
            );
          }
        });
      }
    });
  });
  document.getElementById("compare-range-reset").addEventListener("click", function () {
    range.value = 0;
    range.dispatchEvent(new Event("input"));
  });
}

document.addEventListener("turbo:load", function () {
  Highcharts.charts.forEach(function (chart) {
    if (isObject(chart)) {
      chart.destroy();
    }
  });

  const shotChart = document.getElementById("shot-chart");
  if (shotChart) {
    drawShotChart();
    syncMouseEvents(shotChart);
  }

  const temperatureChart = document.getElementById("temperature-chart");
  if (temperatureChart) {
    drawTemperatureChart();
    syncMouseEvents(temperatureChart);
  }

  const range = document.getElementById("compare-range");
  if (range) {
    comparisonAdjust(range);
  }

  if (window.shotStages?.length > 0) {
    window.shotStages = window.shotStages.map((x) => {
      return { ...x, id: x };
    });
    drawShotStages();
  }
});

window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", function () {
  if (document.body.classList.contains("system")) {
    if (document.getElementById("shot-chart")) {
      drawShotChart();
    }

    if (document.getElementById("temperature-chart")) {
      drawTemperatureChart();
    }
  }
});
