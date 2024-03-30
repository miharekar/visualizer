pin "application"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# use bin/importmap update to update these to the latest version
pin "stimulus-autocomplete" # @3.1.0
pin "el-transition" # @0.0.7

# use rails importmap:check to check for major version changes
pin "highcharts", to: "https://cdn.jsdelivr.net/npm/highcharts@11/es-modules/masters/highcharts.src.js"
pin "highcharts-annotations", to: "https://cdn.jsdelivr.net/npm/highcharts@11/es-modules/masters/modules/annotations.src.js"
pin "highlight.js", to: "https://cdn.jsdelivr.net/npm/highlight.js@11/+esm"

pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/charts", under: "charts"
pin_all_from "app/javascript/custom", under: "custom"
