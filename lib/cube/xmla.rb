module XMLA 
  class << self
    attr_accessor :endpoint, :catalog, :username, :password, :proxy, :disable_ssl_verify
  end

  def self.configure
    yield self if block_given?
  end
end
