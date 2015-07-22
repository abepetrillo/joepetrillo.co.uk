require 'rubygems'
require 'sinatra'
require 'mail'
require 'neography'
require 'pry'

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

get '/training' do
   erb :training
end

post '/training' do
   @neo = Neography::Rest.new(ENV["GRAPHSTORY_URL"]);
   n = @neo.create_node({email: params[:email]})
   selected = [
     :cutting, :hair_up, :drying, :colouring
   ].select do |k|
     params[:type][k] == 'true'
   end.map do |s|
     "c.type =~ '(?i)#{s}'"
   end.join(' OR ')
   puts selected
   query = "MATCH (c:Course) WHERE #{selected} RETURN c"
   result = @neo.execute_query(query)
   types = result['data'].map {|n| @neo.get_node(n.first['self']) }
   types.each do |t|
     @neo.create_relationship('interested_in', n, t)
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


post '/mail' do
  email = params[:email]
  msg = params[:message]
  #Check the email address
  from = Mail::Address.new(email)
  valid = (from.domain != nil)
  mail = Mail.new do
    from     email
    to       ['jospetrillo@gmail.com']
    subject  'Email from joepetrillo.co.uk'
    body     msg
  end

  session[:sent] = valid && mail.deliver
  erb :contact
end
