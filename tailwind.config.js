const colors = require('tailwindcss/colors')
const defaultTheme = require('tailwindcss/defaultTheme')
const forms = require('@tailwindcss/forms')
const prose = require('@tailwindcss/typography')
const fontFamily = defaultTheme.fontFamily
fontFamily['sans'] = ['Inter var', ...defaultTheme.fontFamily.sans]

module.exports = {
  mode: 'jit',
  purge: [
    './app/**/*.js',
    './tmp/*.html.erb'
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        gray: colors.warmGray,
      },
      typography: (theme) => ({
        dark: {
          css: [
            {
              color: theme('colors.gray.400'),
              '[class~="lead"]': {
                color: theme('colors.gray.300'),
              },
              a: {
                color: theme('colors.white'),
              },
              strong: {
                color: theme('colors.white'),
              },
              'ol > li::before': {
                color: theme('colors.gray.400'),
              },
              'ul > li::before': {
                backgroundColor: theme('colors.gray.600'),
              },
              hr: {
                borderColor: theme('colors.gray.200'),
              },
              blockquote: {
                color: theme('colors.gray.200'),
                borderLeftColor: theme('colors.gray.600'),
              },
              h1: {
                color: theme('colors.white'),
              },
              h2: {
                color: theme('colors.white'),
              },
              h3: {
                color: theme('colors.white'),
              },
              h4: {
                color: theme('colors.white'),
              },
              'figure figcaption': {
                color: theme('colors.gray.400'),
              },
              code: {
                color: theme('colors.white'),
              },
              'a code': {
                color: theme('colors.white'),
              },
              pre: {
                color: theme('colors.gray.200'),
                backgroundColor: theme('colors.gray.800'),
              },
              thead: {
                color: theme('colors.white'),
                borderBottomColor: theme('colors.gray.400'),
              },
              'tbody tr': {
                borderBottomColor: theme('colors.gray.600'),
              },
            },
          ],
        },
      }),
    },
    fontFamily: fontFamily,
  },
  variants: {
    extend: {
      typography: ['dark']
    },
  },
  plugins: [forms, prose],
}
