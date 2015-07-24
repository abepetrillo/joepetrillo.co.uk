require 'spec_helper'

require_relative '../app'

describe 'JoePetrillo Website' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it 'says hello' do
    get '/'
    expect(last_response).to be_ok
  end

  describe 'training' do
    context 'get' do
      it 'displays a form' do
        get '/training'
        expect(last_response).to be_ok
      end
    end
    context 'post' do
      context 'given no email' do
        it 'returns an error' do
          post '/training', {}
          expect(last_response.status).to eq 400
        end
      end
      context 'given an invalid email' do
        it 'gives an error' do
          post '/training', email: 'wrongx', type: { cutting: 'true' }
          expect(last_response.status).to eq 400
        end
      end
      context 'given a valid email' do
        context 'and no types' do
          it 'gives an error' do
            post '/training', email: 'test@mailinator.com'
            expect(last_response.status).to eq 400
            post '/training', email: 'test@mailinator.com', type: {}
            expect(last_response.status).to eq 400
          end
        end
        context 'with at least one type' do
          it 'adds interest to db' do
            post '/training', {email: 'test@mailinator.com', type: { cutting: 'true' }}
            expect(last_response.status).to eq 200
          end
        end
      end
    end
  end
end
