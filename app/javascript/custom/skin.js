function setDarkMode() {
  if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
    document.cookie = "browser.colorscheme=dark; path=/"
  } else {
    document.cookie = "browser.colorscheme=light; path=/"
  }
}

document.addEventListener("turbo:load", setDarkMode)
window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", setDarkMode)
