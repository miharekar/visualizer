function setDarkMode() {
  if (document.documentElement.classList.contains("system")) {
    if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
      document.documentElement.classList.add("dark")
    } else {
      document.documentElement.classList.remove("dark")
    }
  }
}
setDarkMode()
window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", setDarkMode)
