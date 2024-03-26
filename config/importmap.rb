pin "application"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# use rails importmap:update to update these to the latest version
pin "stimulus-autocomplete", to: "https://cdn.skypack.dev/pin/stimulus-autocomplete@v3.1.0-sAtS84yDhc0OptdElB2O/mode=imports/optimized/stimulus-autocomplete.js" # source: https://cdn.skypack.dev/stimulus-autocomplete
pin "el-transition", to: "https://cdn.skypack.dev/pin/el-transition@v0.0.7-BadiZFlYOen4UgfYoLiR/mode=imports/optimized/el-transition.js" # source: https://cdn.skypack.dev/el-transition
pin "highcharts", to: "https://cdn.skypack.dev/pin/highcharts@v11.4.0-XcqxbqWpy3Q67GvtWLRq/mode=imports/unoptimized/es-modules/masters/highcharts.src.js" # source: https://cdn.skypack.dev/highcharts/es-modules/masters/highcharts.src.js
pin "highcharts-annotations", to: "https://cdn.skypack.dev/pin/highcharts@v11.4.0-XcqxbqWpy3Q67GvtWLRq/mode=imports/unoptimized/es-modules/masters/modules/annotations.src.js" # source: https://cdn.skypack.dev/highcharts/es-modules/masters/modules/annotations.src.js
pin "highlight.js", to: "https://cdn.skypack.dev/pin/highlight.js@v11.9.0-bSUFWqJEEn57ytKpUEAb/mode=imports/optimized/highlightjs.js" # source: https://cdn.skypack.dev/highlight.js

pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/charts", under: "charts"
pin_all_from "app/javascript/custom", under: "custom"
