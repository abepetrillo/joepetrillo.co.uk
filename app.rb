require 'rubygems'
require 'sinatra'
require 'mail'
require 'neography'
require 'rollbar'
require 'recaptcha'


Recaptcha.configure do |config|
  config.site_key  = ENV['RECAPTCHA_SITE_KEY'] || '6Le7oRETAAAAAETt105rjswZ15EuVJiF7BxPROkY'
  config.secret_key = ENV['RECAPTCHA_SECRET_KEY'] || '6Le7oRETAAAAAL5a8yOmEdmDi3b2pH7mq5iH1bYK'
end

include Recaptcha::Adapters::ControllerMethods
include Recaptcha::Adapters::ViewMethods

Rollbar.configure do |config|
  config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
end

Mail.defaults do
  if Sinatra::Base.production?
    delivery_method :smtp,
      :address => "smtp.sendgrid.net",
      :port => '25',
      :authentication => :plain,
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :domain => ENV['SENDGRID_DOMAIN']
  else
    delivery_method :test
  end
end

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

get '/' do
  erb :index
end

get '/opening_times' do
  erb :opening_times
end

get '/pricing' do
  erb :pricing
end

get '/location' do
  erb :location
end

get '/training' do
   erb :training
end

post '/training' do
  if params[:email] && validate_email(params[:email]) && params[:type]
    @neo = Neography::Rest.new(ENV["GRAPHSTORY_URL"]);
    n = @neo.create_node({email: params[:email]})
    selected = [
      :cutting, :hair_up, :drying, :colouring
    ].select do |k|
      params[:type][k] == 'true'
    end.map do |s|
      "c.type =~ '(?i)#{s}'"
    end.join(' OR ')
    query = "MATCH (c:Course) WHERE #{selected} RETURN c"
    result = @neo.execute_query(query)
    types = result['data'].map {|n| @neo.get_node(n.first['self']) }
    types.each do |t|
      @neo.create_relationship('interested_in', n, t)
    end
    status 200
    session[:training_signup] = true
  else
    status 400
    session[:training_signup] = false
  end
  erb :training
end

get '/gallery' do
  erb :gallery
end

get '/contact' do
  erb :contact
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb "This is a secret place that only <%=session[:identity]%> has access to!"
end

def validate_email(email)
  Mail::Address.new(email).domain != nil
end

def validate_domain(email)
   !(ENV.fetch('BANNED_EMAIL_DOMAINS', '').split(',').include? Mail::Address.new(email).domain)
end


post '/mail' do
  success = verify_recaptcha(action: 'mail', minimum_score: 0.6)
  @email = params[:email]
  @message = params[:message]
  if success
    email = params[:email]
    msg = params[:message]
    #Check the email address
    from = Mail::Address.new(email)
    valid = validate_email(email) && validate_domain(email)
    mail = Mail.new do
      from     email
      to       ENV.fetch('EMAIL_TO_LIST', '').split(',')
      bcc      ENV.fetch('EMAIL_BCC_LIST', '').split(',')
      subject  'Email from joepetrillo.co.uk'
      body     msg
    end
    @email = nil
    @message = nil
    session[:sent] = valid && mail.deliver
  else
    session[:sent] = false
  end
  erb :contact
end
