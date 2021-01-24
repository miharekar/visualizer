const colors = require('tailwindcss/colors')
const defaultTheme = require('tailwindcss/defaultTheme')
const forms = require('@tailwindcss/forms')

module.exports = {
  purge: [
    './app/**/*.js',
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
  plugins: [forms],
}
