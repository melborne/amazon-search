#!/opt/local/bin/ruby1.9
#-*-encoding: utf-8-*-

require "open-uri"
require "cgi"
require "openssl"
require "base64"

class AmazonSearch
  HOSTS = {:ja => "webservices.amazon.co.jp",
           :us => "webservices.amazon.com"}

  attr_reader :message, :query

  def initialize(opts={})
    @access_key = opts[:access_key] || nil
    @secret_key = opts[:secret_key] || '1234567890'
    @host = opts[:host] || host(opts[:country])
    @uri = opts[:uri] || "/onca/xml"
    @verb = opts[:verb] || "GET"
    @message = nil
    @signature = nil
    @query = nil
    @timestamp = time_to_timestamp(opts[:time])
  end

  def query=(query)
    @query = build_query(query)
    @message = [@verb, @host, @uri, @query].join("\n")
    @query
  end

  def signature
    @signature ||= build_signature
  end

  def signed_request
    "http://#{@host}#{@uri}?#{@query}&Signature=#{signature}"
  end

  def send_request
    #access amazon to get xml result
    open(signed_request) { |f| return f.read }
  end
  
#  private
  def escape(string)
    table = [['+', '%20'], ['%28', '('], ['%29', ')'],
             ['%27', "'"], ['%21', '!'], ['%7E', '~']]
    base = CGI.escape(string)
    table.inject(base) { |_base, (from, to)| _base.gsub(from, to) }
  end
  
  def build_query(query)
    case query
    when Hash
      query = {:AWSAccessKeyId => @access_key}.merge(query) if @access_key
      query = {:Timestamp => @timestamp}.merge(query) if @timestamp
      if country = query[:Country]
        @host = host(country)
      end
      query.to_a.sort.
         map { |k, v| "#{escape(k.to_s)}=#{escape(v)}" }.join("&")
    else
      query
    end
  end

  def build_signature
    raise "query is not provided." unless @message
    hmac = OpenSSL::HMAC.new(@secret_key, OpenSSL::Digest::SHA256.new)
    hmac << @message
    #hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, secret_key, message)
    b64 = Base64.encode64(hmac.digest).chomp
    escape(b64).gsub('+', '%2B').gsub('=', '%3D')
  end

  def time_to_timestamp(time)
    if time
      time.to_s.sub(' ', 'T').sub(' ', '').sub(/([-+]\d{2})(\d{2})/, '\1:\2')
    else
      nil
    end
  end

  def host(country)
    case country.to_s.downcase[0..1].to_sym
    when :ja then HOSTS[:ja]
    when :us then HOSTS[:us]
    else HOSTS[:ja]
    end
  end
end
