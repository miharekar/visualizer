const defaultTheme = require("tailwindcss/defaultTheme")

module.exports = {
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/models/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
        serif: ["Ragazzi", ...defaultTheme.fontFamily.serif],
      },
      colors: {
        celeste: {
          50: "#f6f6f4",
          100: "#dbdbd1",
          200: "#cbcbbc",
          300: "#b0af99",
          400: "#9d9b82",
          500: "#8f8a71",
          600: "#7d7562",
          700: "#696154",
          800: "#585148",
          900: "#4a453d",
          950: "#282520",
        },
        terracotta: {
          50: "#fef4f2",
          100: "#fee6e2",
          200: "#fed1ca",
          300: "#fcb0a5",
          400: "#f88271",
          500: "#ee5b45",
          600: "#db3e27",
          700: "#af2e1b",
          800: "#992b1b",
          900: "#7f2a1d",
          950: "#45120a",
        },
        "oxford-blue": {
          50: "#f3f7f8",
          100: "#e0e9ed",
          200: "#c4d5dd",
          300: "#9bb6c5",
          400: "#6a90a6",
          500: "#4f748b",
          600: "#446176",
          700: "#3c5162",
          800: "#3b4b59",
          900: "#313d48",
          950: "#1d262f",
        },
      },
      boxShadow: {
        "inner-sm": "inset 0 1px 2px 0 rgb(0 0 0 / 0.05)",
        "inner-lg": "inset 0 4px 4px 0 rgb(0 0 0 / 0.05)",
      },
      typography: {
        DEFAULT: {
          css: {
            pre: {
              backgroundColor: "#2e3440",
            },
          },
        },
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
}
