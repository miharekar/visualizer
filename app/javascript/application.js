// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
import "@rails/activestorage"
import * as Lexxy from "lexxy"
import "channels/consumer"
import "controllers"
import "custom"

Lexxy.configure({ default: { attachments: false } })
