// Not used yet but can be useful

function rowClickListener(event) {
  let element = event.target || event.srcElement
  if (element.tagName === "TD") {
    Turbo.visit(this.dataset.href)
    return false
  }
}

document.addEventListener("turbo:load", function (xhr) {
  if (document.querySelector("[data-href]")) {
    document.querySelectorAll("[data-href]").forEach(function (row) {
      row.addEventListener("click", rowClickListener)
    })
  }
})
