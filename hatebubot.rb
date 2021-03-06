# encoding: utf-8
require File.dirname(__FILE__) + '/hatebu'
require 'net/irc'
require 'yaml'
require 'mechanize'
require 'uri'
require 'ipaddr'

ERROR_HATEBUNG_MSG = "はてブ禁止でした"
ERROR_IPADDR_MSG = "IPアドレスははてブしない"
ERROR_NGWORD_MSG = "NGワードだったのではてブしない"
ERROR_SITE_MSG = "サイトが見つからないのではてブしない"
TITLE_MSG = "【タイトル】"
SUCCESS_MSG = "【はてブした】"

class HatebuBot < Net::IRC::Client

  def initialize(*args)
    super
  end

  def bot_name= (bot_name)
    @bot_name = bot_name
  end

  def hatebu_setting= (hatebu_setting)
    @hatebu_setting = hatebu_setting
  end

  def channels= (channels)
    @channels = channels
  end

  # 初回接続時
  def on_rpl_welcome(m)
    @channels.each do |channel|
      post JOIN, "##{channel["name"]}", channel["password"]
    end
  end

  # 切断時
  def on_disconnected
  end

  def on_message(m)
    # notice確認
    if m.command != PRIVMSG
      return
    end

    ch = m.params[0];
    msg = m.params[1].force_encoding('utf-8');

    bot_name = @bot_name
    if msg =~ /.*#{bot_name}.+help.*/ then
      post NOTICE, ch, "help"
      return
    end

    if msg =~ /.*#{bot_name}.+ngword.*/ then
      # show hatebu ngword
      @hatebu_setting['ngword'].each do |word|
        post NOTICE, ch, word
      end
      return
    end

    url, title = parseUrl(msg)
    if url == nil
      return
    end

    post NOTICE, ch, TITLE_MSG + " " + title

    # はてブ禁止だったら抜ける
    if msg =~ /.*!.*/ then
      p ERROR_HATEBUNG_MSG
      return
    end

    # NGワードだったら抜ける
    if exist_ngword?(@hatebu_setting['ngword'], msg) then
      p ERROR_NGWORD_MSG
      return
    end

    # はてブする
    success, link = Hatebu.post(@hatebu_setting["oauth"], url)
    if success then
      post NOTICE, ch, SUCCESS_MSG + " " + link
    end
  end

  def parseUrl(message)
    mes = message.tr('　', ' ') # 全角スペース撲滅

    if mes =~ /((http|https):\/\/\S+)\s*/ then
      url = URI.encode($1)
      host = URI.parse(url).host

      begin
        # IPアドレスだったら抜ける
        IPAddr.new(host)
        p ERROR_IPADDR_MSG
        return nil
      rescue ArgumentError
      end

      # 取得できないサイトだったら抜ける
      title = ""
      begin
        p url
        agent = Mechanize.new
        agent.get(url)
        p agent.page.title
        title = agent.page.title
      rescue
        p ERROR_SITE_MSG
        return nil
      end

      return url, title
    end
  end

  def exist_ngword?(ngwords, text)
    ngwords.each do |wd|
      if text.index(wd) != nil then
        return true
      end
    end
    return false
  end

  def debug(err)
#    post NOTICE, @debug_ch, err
  end
end

