# -*- coding: utf-8 -*-
require 'json'
require 'sinatra'

load 'livedoorweather.rb'
load 'msnweather.rb'
load 'gyazo.rb'

using StringToGyazo

get '/' do
  {
    lingr: 'TenkiGirls',
    RUBY_DESCRIPTION: RUBY_DESCRIPTION,
  }
end

post '/' do
  content_type :text
  json = JSON.parse(request.body.string)
  json["events"].select { |e| e["message"] }.map {|e|
    case e["message"]["text"]
    when /^(?:(今日|明日|明後日)の)?天気$/m
      (HELP % [$&, $1]) + GIRLS_GOBI.sample
    when /^天気地方リスト$/m
      LivedoorWether.cities_supported.join(', ')
    when /^(?:(今日|明日|明後日)の(.+)|(.+)の(今日|明日|明後日))の天気$/m
      date = $1 || $4
      city = $2 || $3

      wrap_msn_weather_date(city, date) ||
        wrap_msn_search_date(city, date)
    when /^(.+)の天気((?:を?教えて)?)$/m
      tenki = LivedoorWether.weather_summary($1)
      $2.empty? ? tenki : tenki.to_gyazo
    else
      # do nothing
      ''
    end
  }.join
end

def wrap_livedoor_weather_date(city, date)
  tenki = LivedoorWether.weather_date(city, date, {})
  return if tenki.nil?
  max = tenki['temperature']['max'].nil? ? '--' : tenki['temperature']['max']['celsius']
  min = tenki['temperature']['min'].nil? ? '--' : tenki['temperature']['min']['celsius']
  tenki && "#{tenki['image']['title']}" +
           " #{max}°C/#{min}°C" +
           "\n#{tenki['image']['url']}"
end

def wrap_msn_weather_date(city, date)
  tenki = MSNWeather.weather_date(city, date, {})
  tenki && "#{tenki[:area]}の天気は" +
           "#{tenki[:weather]}" +
           " #{tenki[:temperature][:max]}/#{tenki[:temperature][:min]}" +
           "\n#{tenki[:url]}"
end

def wrap_msn_search_date(city, date)
  tenki = MSNWeather.search_date(city, date)
  tenki && "#{tenki[:area]}の天気は" +
           "#{tenki[:weather]}" +
           " #{tenki[:temperature][:max]}/#{tenki[:temperature][:min]}" +
           "\n#{tenki[:url]}"
end

HELP = 'XXXの%s で%s天気を教え'
GIRLS_GOBI = [
  'ます。べ、べつにあんたのために言ってるわけじゃないんだからね！',
  'るアル',
  'るイカ',
  'るゲソ',
  'るのじゃ',
  'るっちゃ',
  'るヨー',
  'るですー',
  'るですぅ',
  'るにょろ',
  'るですの',
  'るですのー',
  'るみゃ',
  'るにゃ',
  'るにゅ',
  'るもん',
  'るかな、かな',
  'てア・ゲ・ル',
  'ます。とミカサは報告します。',
  'Vim',
]


__END__

* help
天気
今日の天気
明日の天気
明後日の天気

天気地方リスト

* summary
東京の天気

* tenki

明日の東京の天気
東京の明日の天気

