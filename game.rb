# encoding: utf-8
ENV['OPENSHIFT_DATA_DIR'] = './temp/' if ENV['OPENSHIFT_DATA_DIR'].nil?

begin
  udata = File.read(ENV['OPENSHIFT_DATA_DIR'] + 'game_users.txt', :encoding => 'UTF-8')
  udata = JSON.parse udata
rescue
  udata = [ { 'id' => "admin", 'password' => "qwerasdf", 'url' => "qwerasdf" } ]
  File.write ENV['OPENSHIFT_DATA_DIR'] + 'game_users.txt', udata.to_json
end

begin
  mdata = File.read(ENV['OPENSHIFT_DATA_DIR'] + 'game_message_lines.txt', :encoding => 'UTF-8')
  mdata = JSON.parse mdata
rescue
  mdata = [ { 'id' => ":::::", 'message' => '測試用聊天室 須手動重新整理', 'time_stamp' => '::::::' } ]
  File.write ENV['OPENSHIFT_DATA_DIR'] + 'game_message_lines.txt', mdata.to_json
end

users = udata
message_lines = mdata
configure(:development) { set :session_secret, "take_it_down" }
enable :sessions

get '/game' do
  redirect "/game/#{session[:url]}" if session[:url]
  erb :game
end

get '/game/save' do
  File.write ENV['OPENSHIFT_DATA_DIR'] + 'game_users.txt', users.to_json
  File.write ENV['OPENSHIFT_DATA_DIR'] + 'game_message_lines.txt', message_lines.to_json
  204
end

get '/game/:url' do |url|
  user = users.find do |user|
    user['url'] == url
  end
  if user.nil?
    session['url'] = nil
    redirect "/game"
  end
  session[:url] = url
  ml = message_lines.size > 30 ? message_lines[-30] : message_lines
  erb :board, :locals => { :id => user['id'], :url => url, :message_lines => ml }
end

post '/game/login' do
  user = users.find do |user|
    user['id'] == params['id'] and user['password'] == params['password']
  end
  redirect "/game" if user.nil?
  session[:url] = user['url']
  redirect "/game/#{user['url']}"
end

post '/game/post' do
  user = users.find do |user|
    user['url'] == session[:url]
  end
  return 204 if user.nil?
  time = Time.new.strftime("%Y/%m/%d %H:%M")
  message_line = { 'id' => user['id'], 'message' => params['message'], 'time_stamp' => time }
  message_lines << message_line if params['message'] != ''
  redirect "/game/#{user['url']}"
end

post '/verify' do
  begin
    HomuAPI.Verify params
    user = users.find do |u|
      u['id'] == params['id']
    end
    if user.nil?
      url = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
      users << { 'id' => params['id'], 'password' => params['password'], 'url' => url }
    else
      url = user['url']
      user['password'] = params['password']
    end
    redirect "/game/#{url}"
  rescue Exception => e
    '驗證失敗: ' + e.message
  end
end