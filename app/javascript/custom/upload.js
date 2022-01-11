import { Turbo } from "@hotwired/turbo-rails"

document.addEventListener("turbo:load", function () {
  const dropArea = document.getElementById("drop-area");

  if (dropArea) {
    const loader = document.getElementById("loader")
    const error = document.getElementById("error")
    const form = document.getElementById("shot-upload-form")
    const token = document.getElementsByName("csrf-token")[0].content

    const preventDefaults = e => {
      e.preventDefault()
      e.stopPropagation()
    }

    const highlight = e => {
      dropArea.classList.add("bg-emerald-50", "dark:bg-emerald-900")
      dropArea.classList.add("border-emerald-300")
      dropArea.classList.remove("border-stone-300")
    }

    const unhighlight = e => {
      dropArea.classList.remove("bg-emerald-50", "dark:bg-emerald-900")
      dropArea.classList.remove("border-emerald-300")
      dropArea.classList.add("border-stone-300")
    }

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
            loader.classList.add("hidden")
            dropArea.classList.remove("hidden")

            if (xhr.status == 200) {
              Turbo.visit("/shots")
            } else {
              error.classList.remove("hidden")
            }
          }
        },
        false
      );
      [...e.dataTransfer.files].forEach(file => {
        formData.append("files[]", file)
      })
      xhr.send(formData)
    }

    ["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
      dropArea.addEventListener(eventName, preventDefaults, false)
    });

    ["dragenter", "dragover"].forEach(eventName => {
      dropArea.addEventListener(eventName, highlight, false)
    });

    ["dragleave", "drop"].forEach(eventName => {
      dropArea.addEventListener(eventName, unhighlight, false)
    });

    const files = document.getElementById("files")
    if (files) {
      document.getElementById("files").onchange = function () {
        dropArea.classList.add("hidden")
        loader.classList.remove("hidden")
        Turbo.navigator.submitForm(form)
      }
    }

    dropArea.addEventListener("drop", handleDrop, false)
  }
})
