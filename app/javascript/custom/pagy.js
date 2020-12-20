function pagyRequest() {
  const pagy = document.getElementById("pagy")
  const response = JSON.parse(this.responseText)
  pagy.innerHTML += response.html

  if (response.next !== null) {
    loadNextPage(response.next)
  }
}

function loadNextPage(page) {
  const loc = window.location
  let queryParams = new URLSearchParams(loc.search)

  if (window.pagyParams !== undefined) {
    Object.keys(window.pagyParams).forEach(function (key) {
      queryParams.set(key, window.pagyParams[key])
    })
  }
  queryParams.set("page", page)

  const url = loc.origin + loc.pathname + "?" + queryParams.toString()
  let req = new XMLHttpRequest()
  req.addEventListener("load", pagyRequest)
  req.open("GET", url)
  req.send()
}

window.loadNextPagyPage = function () {
  if (window.pagyNextPage !== undefined) {
    loadNextPage(window.pagyNextPage)
  }
}
