pin "application"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# use rails importmap:check to check for major version changes
pin "highcharts", to: "https://cdn.jsdelivr.net/npm/highcharts@11.4.7/es-modules/masters/highcharts.src.min.js"
pin "highcharts-annotations", to: "https://cdn.jsdelivr.net/npm/highcharts@11.4.7/es-modules/masters/modules/annotations.src.min.js"

pin "highlight.js" # downloaded from https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/es/highlight.min.js

# use bin/importmap update to update the local ones below
pin "el-transition" # @0.0.7
pin "match-sorter" # @6.3.4
pin "remove-accents" # @0.5.0
pin "stimulus-autocomplete" # @3.1.0

pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/charts", under: "charts"
pin_all_from "app/javascript/custom", under: "custom"
