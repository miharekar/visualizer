import { Application } from "@hotwired/stimulus"
import { Autocomplete } from "stimulus-autocomplete"
import Appsignal from "@appsignal/javascript"
import { installErrorHandler } from "@appsignal/stimulus"

const isProduction = document.documentElement.dataset.environment === "production"
const appsignal = new Appsignal({ key: isProduction ? "cc9d5ef7-ee02-49a4-8645-fde2bb614bc5" : null }) // gitleaks:allow
const application = Application.start()
installErrorHandler(appsignal, application)
application.register("autocomplete", Autocomplete)

// Configure Stimulus development experience
application.warnings = true
application.debug = false
window.Stimulus = application

export { application }
