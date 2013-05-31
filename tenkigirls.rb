# -*- coding: utf-8 -*-
require 'json'
require 'sinatra'

load 'livedoorweather.rb'
#load 'gyazo.rb'

get '/' do
  "lingr:TenkiGirls"
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
      tenki = LivedoorWether.weather_date({city: city, date: date, only: :image})
      tenki && "#{tenki['title']}\n#{tenki['url']}"
    when /^(.+)の天気((?:を?教えて)?)$/m
      tenki = LivedoorWether.weather_summary({city: $1})
      #$2.empty? ? tenki : tenki.to_gyazo
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

