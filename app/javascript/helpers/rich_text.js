export function plainTextToHtml(value) {
  const container = document.createElement("div")
  container.textContent = value ?? ""

  return container.innerHTML
    .split(/\n{2,}/)
    .map(paragraph => `<p>${paragraph.replaceAll("\n", "<br>")}</p>`)
    .join("")
}
