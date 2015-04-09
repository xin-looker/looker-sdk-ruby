require_relative '../helper'

describe LookerSDK::Client::Dynamic do

  def access_token
    '87614b09dd141c22800f96f11737ade5226d7ba8'
  end

  def sdk_client(swagger, engine)
    faraday = Faraday.new do |conn|
      conn.use LookerSDK::Response::RaiseError
      conn.adapter :rack, engine
    end

    LookerSDK::Client.new do |config|
      config.swagger = swagger
      config.access_token = access_token
      config.faraday = faraday
    end
  end

  def default_swagger
    @swagger ||= JSON.parse(File.read(File.join(File.dirname(__FILE__), 'swagger.json')), :symbolize_names => true)
  end

  def response
    [200, {'Content-Type' => 'application/vnd.looker.v3+json'}, [{}.to_json]]
  end

  def delete_response
    [204, {}, []]
  end

  def confirm_env(env, method, path, body, query)
    env["SERVER_NAME"].must_equal "localhost"
    env["SERVER_PORT"].must_equal "19999"
    env["rack.url_scheme"].must_equal "https"

    env["HTTP_AUTHORIZATION"].must_equal  "token #{access_token}"
    env["REQUEST_METHOD"].must_equal method.to_s.upcase
    env["PATH_INFO"].must_equal path

    JSON.parse(env['rack.input'].gets || '{}', :symbolize_names => true).must_equal body

    q = Hash[ CGI.parse(env["QUERY_STRING"]).map {|key,values| [key.to_sym, values[0]]} ]
    q.must_equal query

    # puts env

    true
  end

  def verify(response, method, path, body={}, query={})
    mock = MiniTest::Mock.new.expect(:call, response){|env| confirm_env(env, method, path, body, query)}
    yield sdk_client(default_swagger, mock)
    mock.verify
  end


  describe "swagger" do
    it "get" do
      verify(response, :get, '/api/3.0/user') do |sdk|
        sdk.me(:query => 'foo')
      end
    end

    it "get with parms" do
      verify(response, :get, '/api/3.0/users/25') do |sdk|
        sdk.user(25)
      end
    end

    it "post" do
      verify(response, :post, '/api/3.0/users', {first_name:'Joe'}) do |sdk|
        sdk.create_user({first_name:'Joe'})
      end
    end

    it "patch" do
      verify(response, :patch, '/api/3.0/users/25', {first_name:'Jim'}) do |sdk|
        sdk.update_user(25, {first_name:'Jim'})
      end
    end

    it "put" do
      verify(response, :put, '/api/3.0/users/25/roles', [10, 20]) do |sdk|
        sdk.set_user_roles(25, [10,20])
      end
    end

    it "delete" do
      verify(delete_response, :delete, '/api/3.0/users/25') do |sdk|
        sdk.delete_user(25)
      end
    end

=begin
    it "get" do
      verify(response, :get, '/api/3.0/user', {}, {foo:'bar', baz:'bla',fat:'true'}) do |sdk|
        sdk.get('/api/3.0/user', {:query => {foo:'bar', baz:'bla', fat:true}})
        # sdk.me(:query => 'foo')
      end
    end
=end

  end
end
