require "test/unit"
require_relative 'amazon_search'

class TestAmazonSearch < Test::Unit::TestCase
  def setup
    @result = "Nace%2BU3Az4OhN7tISqgs1vdLBHBEijWcBeCqL5xN9xg%3D"
    @string_query = "AWSAccessKeyId=00000000000000000000&ItemId=0679722769&Operation=ItemLookup&ResponseGroup=ItemAttributes%2COffers%2CImages%2CReviews&Service=AWSECommerceService&Timestamp=2009-01-01T12%3A00%3A00Z&Version=2009-01-06"
    @hash_query = {
      :AWSAccessKeyId => "00000000000000000000",
      :ItemId => "0679722769",
      :Operation => "ItemLookup",
      :ResponseGroup => "ItemAttributes,Offers,Images,Reviews",
      :Service => "AWSECommerceService",
      :Timestamp => "2009-01-01T12:00:00Z",
      :Version => "2009-01-06"
    }
    @aws = AmazonSearch.new(:country => :us)
  end

  def test_signature_for_string_query
    @aws << @string_query
    assert_equal(@result, @aws.signature)
  end

  def test_signature_for_hash_query
    @aws << @hash_query
    assert_equal(@result, @aws.signature)
  end

  def test_build_query
    assert_equal(@string_query, @aws.build_query(@hash_query))
  end

  def test_escaping
    wrds = %w[- _ . ~ ( ) ! ']
    no_escape = [wrds, wrds].transpose
    escape = [[' ', '%20'], ['*', '%2A'], ['+', '%2B'] ]
    (escape+no_escape).each { |orig, encoded| assert_equal(encoded, @aws.escape(orig))}
  end

  def test_signed_uri
    access_key = "00000000000000000000"
    secret_key = "1234567890"
    host = "ecs.amazonaws.com"
    uri = "/onca/xml"
    query = {
        :Service        => "AWSECommerceService",
        :Version        => "2009-03-31",
        :Operation      => "ItemSearch",
        :SearchIndex    => "Books",
        :Keywords       => "harry potter",
        :Timestamp      => "2010-10-04T09:55:20.000Z",
        :AWSAccessKeyId => access_key
    }
    result = "http://ecs.amazonaws.com/onca/xml?AWSAccessKeyId=00000000000000000000&Keywords=harry%20potter&Operation=ItemSearch&SearchIndex=Books&Service=AWSECommerceService&Timestamp=2010-10-04T09%3A55%3A20.000Z&Version=2009-03-31&Signature=zh9roYcUjUJRitByfS7bPzVKwDfjtM4ReqrPNyoogFY%3D" 
    aws = AmazonSearch.new(:access_key => access_key,
                           :secret_key => secret_key,
                           :host => host,
                           :uri => uri)
    aws << query
    assert_equal(result, aws.signed_request)  
  end
end

