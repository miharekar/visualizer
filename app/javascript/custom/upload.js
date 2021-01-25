import { Turbo } from "@hotwired/turbo-rails"

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
      dropArea.classList.add("bg-green-50", "dark:bg-green-900")
      dropArea.classList.add("border-green-300")
      dropArea.classList.remove("border-gray-300")
    };

    const unhighlight = e => {
      dropArea.classList.remove("bg-green-50", "dark:bg-green-900")
      dropArea.classList.remove("border-green-300")
      dropArea.classList.add("border-gray-300")
    };

    const handleDrop = e => {
      dropArea.classList.add("hidden")
      loader.classList.remove("hidden")

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
              } else {
                let queryParams = new URLSearchParams(window.location.search)
                let id = JSON.parse(xhr.responseText).id
                Turbo.visit("/shots/" + id + "?" + queryParams.toString())
              }
            } else {
              loader.classList.add("hidden")
              error.classList.remove("hidden")
              Array.from(error.children).forEach(child => {
                child.classList.remove("hidden")
              })
              dropArea.classList.remove("hidden")
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

    document.getElementById("files").onchange = function () {
      dropArea.classList.add("hidden")
      loader.classList.remove("hidden")
      form.requestSubmit()
    };

    dropArea.addEventListener("drop", handleDrop, false)
  }
})
