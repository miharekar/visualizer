document.addEventListener("turbolinks:load", function (xhr) {
  if (document.getElementsByClassName("shot-range").length > 0) {
    Array.from(document.getElementsByClassName("shot-range")).forEach((el) => {
      target = el.parentElement.getElementsByClassName("shot-range-target")[0]
      el.addEventListener("input", function () {
        target.value = el.value
        target.style.color = "#fff"
        target.style.backgroundColor = "hsl(" + (124 / 100 * parseInt(el.value)) + ", 70%, 50%)"
      })
    });
  }
})
