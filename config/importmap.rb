# frozen_string_literal: true

pin "application"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@hotwired/turbo-rails", to: "turbo.js"
pin "@hotwired/stimulus", to: "stimulus.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "stimulus-autocomplete", to: "https://cdn.jsdelivr.net/npm/stimulus-autocomplete@3.0.0-rc.5/src/autocomplete.js"
pin "el-transition", to: "https://cdn.jsdelivr.net/npm/el-transition@0.0.7/index.js"
pin "highcharts", to: "https://cdn.jsdelivr.net/npm/highcharts@9.3.2/es-modules/masters/highcharts.src.js"

pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/charts", under: "charts"
pin_all_from "app/javascript/custom", under: "custom"
