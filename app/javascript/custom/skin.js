function setDarkMode() {
  if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
    if (document.body.classList.contains("system")) {
      document.body.classList.add("dark")
    }
  } else {
    if (document.body.classList.contains("system")) {
      document.body.classList.remove("dark")
    }
  }
}

document.addEventListener("turbo:load", setDarkMode)
window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", setDarkMode)
