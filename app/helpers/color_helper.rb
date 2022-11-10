# frozen_string_literal: true

module ColorHelper
  def enjoyment_hex(value)
    hsl_to_hex(1.2 * value.to_i, 70, 50)
  end

  private

  def hsl_to_hex(h, s, l)
    h /= 360.0
    s /= 100.0
    l /= 100.0

    if s.zero?
      r = g = b = l
    else
      q = (l < 0.5) ? l * (1 + s) : l + s - l * s
      p = 2 * l - q
      r = hue_to_rgb(p, q, h + 1 / 3.0)
      g = hue_to_rgb(p, q, h)
      b = hue_to_rgb(p, q, h - 1 / 3.0)
    end
    hex = [r, g, b].map { |c| sprintf "%02x", (c * 255).round }.join
    "#" + hex.upcase
  end

  def hue_to_rgb(p, q, t)
    t += 1 if t.negative?
    t -= 1 if t > 1
    if t < 1 / 6.0
      p + (q - p) * 6 * t
    elsif t < 1 / 2.0
      q
    elsif t < 2 / 3.0
      p + (q - p) * (2 / 3.0 - t) * 6
    else
      p
    end
  end
end
