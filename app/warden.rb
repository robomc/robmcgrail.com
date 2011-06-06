class User
  include DataMapper::Resource
  property :id,         Serial # primary serial key
  property :username,   String,  :required => true,  :length => 20
  property :password,   String,  :required => true,  :length => 64

  def self.authenticate(u,p)
    user = first(:username => u)
    if user.nil?
      return nil
    else
      if user.password.make_matchable == p
        return user
      else
        return nil
      end
    end
  end
end


Warden::Strategies.add(:password) do
  # Find out why params hash doesn't work
  def username
    env["rack.request.query_hash"]["username"]
  end

  def password
    env["rack.request.query_hash"]["password"]
  end

  def valid?
    username || password
  end

  def authenticate!
    user = User.authenticate(username,password)
    # Tighten this up
    unless user.nil?
      success!(user)
    else
      fail!("Invalid username or password")
    end
  end
end

Warden::Manager.serialize_into_session do |user|
  user.id
end

Warden::Manager.serialize_from_session do |id|
  User.get(id)
end

helpers do
  def authorize!(failure_path=nil)
    unless env['warden'].authenticated?
#    session[:return_to] = request.path if options.auth_use_referrer
      redirect failure_path || '/unauthenticated'
    end
  end
end


get '/unauthenticated/?' do
  status 401
  flash[:error] = 'You can\'t see this'
  redirect '/login'
end


post '/unauthenticated/?' do
  status 401
  flash[:error] = 'Wrong username and password'
  redirect '/login'
end


get '/login/?' do
  haml :'warden/login'
end


post '/login/?' do
  request.env['warden'].authenticate!(:password)
  flash[:success] = 'Logged in'
  redirect '/'
end
