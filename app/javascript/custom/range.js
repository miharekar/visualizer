document.addEventListener("turbo:load", function (xhr) {
  if (document.getElementsByClassName("shot-range").length > 0) {
    Array.from(document.getElementsByClassName("shot-range")).forEach((el) => {
      dot = el.parentElement.getElementsByClassName("dot")[0]
      number = el.parentElement.getElementsByClassName("number")[0]
      el.addEventListener("input", function () {
        number.innerHTML = el.value
        dot.style.backgroundColor = "hsl(" + (124 / 100 * parseInt(el.value)) + ", 70%, 50%)"
      })
    });
  }
})
