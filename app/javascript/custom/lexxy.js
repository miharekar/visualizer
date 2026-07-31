import * as Lexxy from "lexxy"

Lexxy.configure({
  default: {
    attachments: false
  }
})

document.addEventListener("lexxy:file-accept", event => event.preventDefault())
