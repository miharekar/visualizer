import { Application } from "@hotwired/stimulus"
import { Autocomplete } from "stimulus-autocomplete"

import Appsignal from "@appsignal/javascript"
const appsignal = new Appsignal({ key: "cc9d5ef7-ee02-49a4-8645-fde2bb614bc5" })
import { installErrorHandler } from "@appsignal/stimulus"

const application = Application.start()
installErrorHandler(appsignal, application)
application.register("autocomplete", Autocomplete)

// Configure Stimulus development experience
application.warnings = true
application.debug = false
window.Stimulus = application

export { application }
