function convertTimeToLocal() {
  if (document.getElementsByClassName("local-time").length > 0) {
    const locale = window.navigator.userLanguage || window.navigator.language

    Array.from(document.getElementsByClassName("local-time")).forEach((el) => {
      const time = new Date(el.dataset.time * 1000)
      el.innerHTML = time.toLocaleString(locale)
    });
  }
}

function setTimezoneCookie() {
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone
  document.cookie = "browser.timezone=" + (timezone || "") + "; path=/";
}

document.addEventListener("turbolinks:load", function (xhr) {
  convertTimeToLocal()
  setTimezoneCookie()
})
