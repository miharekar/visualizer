# frozen_string_literal: true

pin "application", preload: true
pin "@rails/activestorage", to: "activestorage.esm.js", preload: true
pin "@rails/actioncable", to: "actioncable.esm.js", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "stimulus-autocomplete", to: "https://ga.jspm.io/npm:stimulus-autocomplete@3.0.2/src/autocomplete.js", preload: true
pin "el-transition", to: "https://ga.jspm.io/npm:el-transition@0.0.7/index.js", preload: true
pin "highcharts", to: "https://code.highcharts.com/es-modules/masters/highcharts.src.js"
pin "highcharts-annotations", to: "https://code.highcharts.com/es-modules/masters/modules/annotations.src.js"

pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/charts", under: "charts"
pin_all_from "app/javascript/custom", under: "custom"
