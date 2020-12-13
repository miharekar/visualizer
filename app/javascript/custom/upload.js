document.addEventListener("turbolinks:load", function () {
  const dropArea = document.getElementById("drop-area");
  if (dropArea) {


    const form = document.getElementById("shot-upload-form");
    const token = document.getElementsByName('csrf-token')[0].content

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
      const file = e.dataTransfer.files[0]
      let xhr = new XMLHttpRequest()
      let formData = new FormData()

      xhr.open("POST", form.action + "?drag=1", true)
      xhr.setRequestHeader("X-CSRF-Token", token)
      xhr.addEventListener(
        "readystatechange",
        function () {
          if (dropArea.dataset.bulk === "true") {
            Turbolinks.visit("/shots")
          } else {
            if (xhr.readyState == 4 && xhr.status == 200) {
              let queryParams = new URLSearchParams(window.location.search)
              let id = JSON.parse(xhr.responseText).id
              Turbolinks.visit("/shots/" + id + "?" + queryParams.toString())
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
