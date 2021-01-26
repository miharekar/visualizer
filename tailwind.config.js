const colors = require('tailwindcss/colors')
const defaultTheme = require('tailwindcss/defaultTheme')
const forms = require('@tailwindcss/forms')

module.exports = {
  purge: [
    './app/**/*.js',
    './tmp/*.html.erb'
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
