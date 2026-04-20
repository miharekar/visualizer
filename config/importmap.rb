pin "application"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin "highlight.js" # downloaded from https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/es/highlight.min.js

# use bin/importmap update to update the local ones below
pin "@appsignal/javascript", to: "@appsignal--javascript.js" # @1.6.1
pin "@appsignal/stimulus", to: "@appsignal--stimulus.js" # @1.0.21
pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.13
pin "@yaireo/tagify", to: "@yaireo--tagify.js" # @4.37.1
pin "el-transition" # @0.0.7
pin "highcharts" # @12.6.0
pin "highcharts/highcharts-more", to: "highcharts--highcharts-more.js" # @12.6.0
pin "highcharts/modules/annotations", to: "highcharts--modules--annotations.js" # @12.6.0
pin "https" # @2.1.0
pin "match-sorter" # @8.3.0
pin "remove-accents" # @0.5.0
pin "stimulus-autocomplete" # @3.1.0
pin "tslib" # @2.8.1

pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/helpers", under: "helpers"
pin_all_from "app/javascript/custom", under: "custom"
