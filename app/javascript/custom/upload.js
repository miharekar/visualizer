import * as Turbo from "@hotwired/turbo";

function fadeAwayFlash() {
  setTimeout(function () {
    Array.from(document.getElementsByClassName("fade-away")).forEach((el) => {
      el.style.height = el.scrollHeight + "px";
      window.setTimeout(function () {
        el.style.height = "0";
        el.style.opacity = "0";
      }, 1);
    });
  }, 5000);
}

document.addEventListener("turbo:load", function () {
  const dropArea = document.getElementById("drop-area");

  if (dropArea) {
    const loader = document.getElementById("loader");
    const error = document.getElementById("error");
    const form = document.getElementById("shot-upload-form");
    const token = document.getElementsByName("csrf-token")[0].content

    const preventDefaults = e => {
      e.preventDefault()
      e.stopPropagation()
    };

    const highlight = e => {
      dropArea.classList.add("highlight")
    };

    const unhighlight = e => {
      dropArea.classList.remove("highlight")
    };

    const handleDrop = e => {
      dropArea.classList.add("d-none")
      loader.classList.remove("d-none")

      const file = e.dataTransfer.files[0]
      let xhr = new XMLHttpRequest()
      let formData = new FormData()

      xhr.open("POST", form.action + "?drag=1", true)
      xhr.setRequestHeader("X-CSRF-Token", token)
      xhr.addEventListener(
        "readystatechange",
        function () {
          if (xhr.readyState == 4) {
            if (xhr.status == 200) {
              if (dropArea.dataset.bulk === "true") {
                Turbo.visit("/shots")
                fadeAwayFlash()
              } else {
                let queryParams = new URLSearchParams(window.location.search)
                let id = JSON.parse(xhr.responseText).id
                Turbo.visit("/shots/" + id + "?" + queryParams.toString())
              }
            } else {
              loader.classList.add("d-none")
              error.classList.remove("d-none")
            }
          }
        },
        false
      );
      if (dropArea.dataset.bulk === "true") {
        [...e.dataTransfer.files].forEach(file => {
          formData.append("files[]", file)
        })
      } else {
        formData.append("file", e.dataTransfer.files[0])
      }
      xhr.send(formData)
    };

    ["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
      dropArea.addEventListener(eventName, preventDefaults, false)
    });

    ["dragenter", "dragover"].forEach(eventName => {
      dropArea.addEventListener(eventName, highlight, false)
    });

    ["dragleave", "drop"].forEach(eventName => {
      dropArea.addEventListener(eventName, unhighlight, false)
    });

    dropArea.addEventListener("drop", handleDrop, false)
  }
})
