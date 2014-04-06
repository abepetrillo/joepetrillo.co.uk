require 'rubygems'
require 'sinatra'
require 'mail'
require 'debugger' unless Sinatra::Base.production?
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

before '/secure/*' do
  if !session[:identity] then
    session[:previous_url] = request.path
    @error = 'Sorry guacamole, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
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

 
post '/mail' do
  email = params[:email]
  msg = params[:message]
  #Check the email address
  from = Mail::Address.new(email)
  valid = (from.domain != nil)
  mail = Mail.new do
    from     email
    to       'abe.petrillo@gmail.com'
    subject  'Email from joepetrillo.co.uk'
    body     msg
  end
  
  session[:sent] = valid && mail.deliver
  erb :contact
end
