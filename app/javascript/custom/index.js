const custom = require.context('.', true, /\.js$/)
custom.keys().forEach(custom)
