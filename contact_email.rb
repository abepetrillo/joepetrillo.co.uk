require 'sinatra'
require 'action_mailer'
 
class Mailer < ActionMailer::Base
  def contact(from)
    mail(
      :to      => "abe.petrillo@gmail.com",
      :from    => from,
      :subject => "Test") do |format|
        format.text
        format.html
    end
  end
end
 
configure do
  set :root,    File.dirname(__FILE__)
  set :views,   File.join(Sinatra::Application.root, 'views')
  set :haml,    { :format => :html5 }
    
  if production?
    ActionMailer::Base.smtp_settings = {
      :address => "smtp.sendgrid.net",
      :port => '25',
      :authentication => :plain,
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :domain => ENV['SENDGRID_DOMAIN'],
    }
    ActionMailer::Base.view_paths = File.join(Sinatra::Application.root, 'views')
  else
    ActionMailer::Base.delivery_method = :file
    ActionMailer::Base.file_settings = { :location => File.join(Sinatra::Application.root, 'tmp/emails') }
    ActionMailer::Base.view_paths = File.join(Sinatra::Application.root, 'views')
  end
end
 
post '/mail' do
  email = Mailer.contact('abe@mrtechie.ie')
  email.deliver
end