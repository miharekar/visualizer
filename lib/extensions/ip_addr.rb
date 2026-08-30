require "ipaddr"

class IPAddr
  def multicast?
    IPAddr.new(ipv4? ? "224.0.0.0/4" : "ff00::/8").include?(self)
  end
end
