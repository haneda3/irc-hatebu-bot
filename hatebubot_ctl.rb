# encoding: utf-8
require 'rubygems'
require 'daemons'
require 'yaml'

require File.dirname(__FILE__) + '/hatebubot.rb'

$hatebu_setting_path = File.dirname(__FILE__) + '/config.hatebu.yaml'
$irc_setting_path = File.dirname(__FILE__) + '/config.irc.yaml'

$hatebu_setting = YAML::load_file($hatebu_setting_path)
$irc_setting = YAML::load_file($irc_setting_path)

$server = $irc_setting['server']
$channels = $irc_setting['channels']

def run
  hb = HatebuBot.new($server['host'], $server['port'],
    {:nick => $server['nick'], :user => $server['user'], :real => $server['real']})
  hb.hatebu_setting = $hatebu_setting
  hb.channels = $irc_setting["channels"]
  hb.start
end

Daemons.run_proc("HatebuBot", {:app_name => "hatebubot"}) do
  run
end
#Daemons.run(File.dirname(__FILE__) + '/hatebubot.rb')
