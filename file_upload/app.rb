require 'sinatra'
require 'thread'
require 'webrick'
require 'cgi'  # CGIモジュールを追加

set :server, 'webrick'
UPLOAD_FOLDER = './uploads'

# アプリケーションの起動時にuploadsディレクトリが存在しない場合に自動的に作成
Dir.mkdir(UPLOAD_FOLDER) unless File.exist?(UPLOAD_FOLDER)

set :public_folder, UPLOAD_FOLDER

# エラーハンドリングの設定を追加
set :show_exceptions, :after_handler

get '/' do
  <<-HTML
  <h1>ファイルをアップロード</h1>
  <form action="/upload" method="post" enctype="multipart/form-data">
    <input type="file" name="file">
    <input type="submit" value="アップロード">
  </form>
  HTML
end

post '/upload' do
  if params[:file] && params[:file][:filename]
    filename = params[:file][:filename].force_encoding('UTF-8')
    encoded_filename = CGI.escape(filename)  # ファイル名をURIエンコード
    file = params[:file][:tempfile]

    File.open("#{UPLOAD_FOLDER}/#{encoded_filename}", 'wb') do |f|
      f.write(file.read)
    end

    Thread.new do
      sleep 3600
      File.delete("#{UPLOAD_FOLDER}/#{encoded_filename}")
    end

    redirect to("/view/#{encoded_filename}")  # エンコードされたファイル名を使用
  else
    "アップロードに失敗しました"
  end
end

get '/view/:filename' do
  encoded_filename = params[:filename]
  filename = CGI.unescape(encoded_filename)  # ファイル名をURIデコード
  <<-HTML
  <h1>#{filename}の内容を閲覧</h1>
  <!-- ここにファイルの内容や詳細を表示するコードを追加 -->
  <a href="/#{encoded_filename}" download>ファイルをダウンロード</a>
  HTML
end

# 404エラー（ページが見つからない）のハンドラ
error Sinatra::NotFound do
  'ページが見つかりません'
end

# 500エラー（サーバー内部エラー）のハンドラ
error 500 do
  'サーバー内部エラーが発生しました'
end

