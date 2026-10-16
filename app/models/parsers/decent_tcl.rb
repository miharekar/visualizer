require "strscan"

module Parsers
  class DecentTcl < Base
    DATA_LABELS = %w[espresso_pressure espresso_weight espresso_flow espresso_flow_weight espresso_temperature_basket espresso_temperature_mix espresso_water_dispensed espresso_temperature_goal espresso_flow_weight_raw espresso_pressure_goal espresso_flow_goal espresso_state_change].freeze
    EXTRA_KEYS = EXTRA_DATA_CAPTURE.to_set.freeze
    PROFILE_KEYS = PROFILE_FIELDS.to_set.freeze
    OPEN_BRACE = "{".ord
    CLOSE_BRACE = "}".ord
    BRACE_PATTERNS = [/[{}\\]/, /[{}]/].freeze
    BACKSLASH = "\\".ord
    ESCAPES = {"n" => "\n", "t" => "\t", "r" => "\r", "f" => "\f", "v" => "\v"}.freeze

    class Error < StandardError; end

    def parse
      pairs_in(top_level_list).each do |name, value|
        case name
        when "clock" then @start_time = Time.at(value.to_i).utc
        when "espresso_elapsed" then @timeframe = value.split
        when *DATA_LABELS then @data[name] = value.split
        when "settings" then extract_settings(value)
        when "profile" then extract_profile(value)
        end
      end
      @profile_title = @profile_fields["profile_title"]
    end

    private

    def top_level_list
      text = file.b
      list_elements(text, top_level: true)
    rescue Error
      start = text.index("machine {")
      raise unless start

      begin
        list_elements(without_machine(text, start), top_level: true)
      rescue Error
        list_elements(text.byteslice(0, start), top_level: true)
      end
    end

    def without_machine(text, start)
      stop = text.index(/\n(?=[A-Za-z_])/, start)
      stop ? text.byteslice(0, start) + text.byteslice(stop..) : text.byteslice(0, start)
    end

    def extract_settings(value)
      pairs_in(list_elements(value)).each do |name, setting|
        name = name.strip
        extra = EXTRA_KEYS.include?(name)
        profile = PROFILE_KEYS.include?(name)
        next unless extra || profile

        setting = setting.force_encoding("UTF-8")
        @extra[name] = setting if extra
        @profile_fields[name] = setting if profile
      end
    end

    def extract_profile(value)
      json = JSON.parse("{#{value.dup.force_encoding("UTF-8")}}")
      @profile_fields["json"] = json if json.present?
    rescue StandardError
      nil
    end

    def pairs_in(elements)
      elements.each_slice(2).select { |pair| pair.size == 2 }
    end

    def list_elements(text, top_level: false)
      scanner = StringScanner.new(text)
      elements = []
      loop do
        scanner.skip(/[ \t\n\r]+/)
        break if scanner.eos?

        elements << if scanner.peek_byte != OPEN_BRACE
          bare_word(scanner)
        elsif top_level && elements.size.odd? && elements.last == "profile"
          profile_word(scanner)
        else
          braced_word(scanner)
        end
      end
      elements
    end

    def braced_word(scanner)
      start = scanner.pos + 1
      BRACE_PATTERNS.each do |pattern|
        scanner.pos = start
        body = balanced_body(scanner, pattern)
        return body if body
      end
      raise Error, "unbalanced brace"
    end

    def balanced_body(scanner, pattern)
      start = scanner.pos
      depth = 1
      while depth.positive?
        return unless scanner.skip_until(pattern)

        case scanner.string.getbyte(scanner.pos - 1)
        when OPEN_BRACE then depth += 1
        when CLOSE_BRACE then depth -= 1
        else scanner.getch
        end
      end
      scanner.string.byteslice(start, scanner.pos - 1 - start)
    end

    def profile_word(scanner)
      start = scanner.pos + 1
      scanner.getch
      body = scanner.skip_until(/\n\}(?=[ \t\r\n]|\z)/) && scanner.string.byteslice(start, scanner.pos - 1 - start)
      return body if body && !body.match?(/\n[^ \t\r\n]/)

      scanner.pos = start - 1
      braced_word(scanner)
    end

    def bare_word(scanner)
      start = scanner.pos
      word = scanner.scan(/[^ \t\n\r\\]+/)
      return word if scanner.peek_byte != BACKSLASH

      scanner.pos = start
      scanner.scan(/(?:\\.|[^ \t\n\r\\]|\\)+/m).gsub(/\\(.)/m) { unescape($1) }
    end

    def unescape(char)
      ESCAPES.fetch(char, char)
    end
  end
end
