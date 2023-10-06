const defaultTheme = require("tailwindcss/defaultTheme")

module.exports = {
  content: ["./public/*.html", "./app/helpers/**/*.rb", "./app/javascript/**/*.js", "./app/views/**/*.{erb,haml,html,slim}"],
  darkMode: "class",
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
      colors: {
        "dark-moss-green": { DEFAULT: "#606c38", 100: "#13160b", 200: "#262b16", 300: "#394121", 400: "#4c562c", 500: "#606c38", 600: "#88994f", 700: "#a9b876", 800: "#c5d0a3", 900: "#e2e7d1" },
        "pakistan-green": { DEFAULT: "#283618", 100: "#080b05", 200: "#101509", 300: "#18200e", 400: "#1f2a13", 500: "#283618", 600: "#547133", 700: "#80ac4d", 800: "#aac987", 900: "#d5e4c3" },
        cornsilk: { DEFAULT: "#fefae0", 100: "#5d5103", 200: "#baa206", 300: "#f8dc27", 400: "#fbeb84", 500: "#fefae0", 600: "#fefbe7", 700: "#fefced", 800: "#fffdf3", 900: "#fffef9" },
        "earth-yellow": { DEFAULT: "#dda15e", 100: "#34210b", 200: "#684216", 300: "#9d6321", 400: "#d1842c", 500: "#dda15e", 600: "#e4b57f", 700: "#ebc79f", 800: "#f1dabf", 900: "#f8ecdf" },
        "midnight-green": { DEFAULT: "#073b3a", 100: "#010c0c", 200: "#031817", 300: "#042423", 400: "#062f2f", 500: "#073b3a", 600: "#108b89", 700: "#1adad7", 800: "#60ecea", 900: "#b0f6f5" },
        pistachio: { DEFAULT: "#9cd08f", 100: "#1b3215", 200: "#35632a", 300: "#50953e", 400: "#71bc5e", 500: "#9cd08f", 600: "#b0daa6", 700: "#c4e3bc", 800: "#d8ecd2", 900: "#ebf6e9" },
        "tigers-eye": { DEFAULT: "#bc6c25", 100: "#251507", 200: "#4b2b0f", 300: "#704016", 400: "#96561e", 500: "#bc6c25", 600: "#d98840", 700: "#e3a570", 800: "#ecc3a0", 900: "#f6e1cf" },
        "dark-purple": { DEFAULT: "#2c0e37", 100: "#09030b", 200: "#120617", 300: "#1b0922", 400: "#240c2d", 500: "#2c0e37", 600: "#65217f", 700: "#9d33c4", 800: "#bf74db", 900: "#dfb9ed" },
        raspberry: { DEFAULT: "#d81159", 100: "#2b0412", 200: "#570724", 300: "#820b36", 400: "#ae0e49", 500: "#d81159", 600: "#ee3378", 700: "#f3669a", 800: "#f799bb", 900: "#fbccdd" },
      },
    },
  },
  plugins: [require("@tailwindcss/forms"), require("@tailwindcss/aspect-ratio"), require("@tailwindcss/typography"), require("@tailwindcss/container-queries")],
}
