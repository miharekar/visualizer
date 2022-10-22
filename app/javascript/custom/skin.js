import { Turbo } from "@hotwired/turbo-rails"

function setDarkMode() {
  if (document.body.classList.contains("system")) {
    if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
      if (!document.body.classList.contains("dark")) {
        document.cookie = "browser.colorscheme=dark; path=/"
        document.body.classList.add("dark")
        Turbo.cache.clear()
      }
    } else {
      if (document.body.classList.contains("dark")) {
        document.cookie = "browser.colorscheme=light; path=/"
        document.body.classList.remove("dark")
        Turbo.cache.clear()
      }
    }
  }
}
setDarkMode()
window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", setDarkMode)
