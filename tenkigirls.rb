# -*- coding: utf-8 -*-
require 'json'
require 'sinatra'

load 'livedoorweather.rb'

get '/' do
  "lingr:TenkiGirls"
end

post '/' do
  content_type :text
  json = JSON.parse(request.body.string)
  json["events"].select { |e| e["message"] }.map {|e|
    case e["message"]["text"]
    when /^(?:(今日|明日|明後日)の)?天気$/m
      (HELP % [$&, $1]) + girls_gobi
    when /^天気地方リスト$/m
      LivedoorWether::get_supported_city.join(',')
    when /^(?:(今日|明日|明後日)の(.+)|(.+)の(今日|明日|明後日))の天気$/m
      date = $1 || $4
      city = $2 || $3
      tenki = LivedoorWether::get_weather_date(:city => city, :date => date, :only => :image)
      tenki['title'] unless tenki.nil?
    when /^(.+)の天気$/m
      LivedoorWether::get_weather_summary(:city => $1)
    else
      # do nothing
      ''
    end
  }.join
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
]

def girls_gobi
  return GIRLS_GOBI[rand GIRLS_GOBI.length]
end


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

