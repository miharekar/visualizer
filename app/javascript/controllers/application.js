import { Application } from "@hotwired/stimulus"
import { Autocomplete } from '../custom/stimulus-autocomplete'

const application = Application.start()
application.register('autocomplete', Autocomplete)
// Configure Stimulus development experience
application.warnings = true
application.debug = true
window.Stimulus = application

export { application }
