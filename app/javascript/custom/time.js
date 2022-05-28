function setTimezoneCookie() {
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone
  document.cookie = "browser.timezone=" + (timezone || "") + "; path=/"
}

document.addEventListener("turbo:load", function () {
  setTimezoneCookie()
})
