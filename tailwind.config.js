const colors = require('tailwindcss/colors')
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  purge: [
    './app/**/*.slim',
    './app/**/*.erb',
    './app/**/*.html'
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        gray: colors.warmGray,
      }
    },
    fontFamily: {
      sans: ['Inter var', ...defaultTheme.fontFamily.sans],
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
