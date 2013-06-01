# -*- coding: utf-8 -*-
require 'nokogiri'
require 'open-uri'

module MSNWeather
  TOP_URL = 'http://weather.jp.msn.com/'
  REGEX_URL = Regexp.escape('http://weather.jp.msn.com/local.aspx?wealocations=wc:')
  SEARCH_URL = 'http://weather.jp.msn.com/search.aspx?weasearchstr='


  def weather(city)
    self.init_url if @url_hash.nil?

    return unless @url_hash.key? city

    doc = Nokogiri::HTML(open(@url_hash[city]))
    self.scrape_foreigner(doc)
  end

  def weather_date(city, date, options)
    result = self.weather(city)
    return if result.nil?

    forecast = result.find { |f| f[:day] == date }

    if options.key? :only
      forecast && forecast[options[:only]]
    else
      forecast
    end
  end

  def search(city)
    doc = Nokogiri::HTML(open(URI.escape(SEARCH_URL + city)))
    result = doc.css('table#results a').first
    result_city = city
    if result
      result_city = result.text
      doc = Nokogiri::HTML(open(TOP_URL + result['href']))
    end

    self.scrape_japanese_spot(doc) ||
      self.scrape_foreigner(doc) ||
      self.scrape_japanese_area(doc)
  end

  def search_date(city, date)
    forecast = self.search(city)
    return if forecast.nil?

    case date
    when '今日'
      forecast[0]
    when '明日'
      forecast[1]
    when '明後日'
      forecast[2]
    else
      nil
    end
  end

  module_function :weather, :weather_date, :search, :search_date

  private
  def self.init_url
    @url_hash = {}
    doc = Nokogiri::HTML(open('http://weather.jp.msn.com/worldtop.aspx'))
    doc.css('div#browseWorld + div a').each do |node|
      @url_hash[node.text] = "#{node['href']}&q=forecast:tenday'" if %r|^#{REGEX_URL}| =~ node['href']
    end
  end

  def self.scrape_foreigner(doc)
    anc = doc.css('div#localNav a').find { |node| /forecast:tenday$/ =~ node['href'] }

    return if anc.nil?

    tenday = nil
    doc = Nokogiri::HTML(open(TOP_URL + anc['href']))
    doc.css('div#tenDay table').each do |node|
      tenday = node.children[3,10].map {|day|
        td1 = day.children[0].children
        td2 = day.children[1].children
        {
          :day => td1[0].text,
          :date => td1[1].text,
          :url => td2[0]['src'],
          :weather => td2[1].text,
        }
      }
    end

    tenday
  end

  # 市区町村
  def self.scrape_japanese_area(doc)
    today = self.scrape_oneday(doc, 'pptToday')

    return if today.empty?

    tommorow = self.scrape_oneday(doc, 'pptTomorrow')
    sixday = self.scrape_sixday(doc)

    return today + tommorow + sixday
  end

  # 代表都市
  def self.scrape_japanese_spot(doc)
    twoday = doc.css('div#twoday > div > div > div:first-child').map {|node|
      children = node.children
      {
        :day => children[0].text,
        :date => children[0].text,
        :url => children[1]['src'],
        :weather => children[2].text,
      }
    }

    return if twoday.empty?

    sixday = self.scrape_sixday(doc)

    twoday + sixday
  end

  def self.scrape_oneday(doc, id)
    doc.css("div##{id} > div:nth-of-type(1)").map {|node|
      date = node.children[0].text
      children = node.children[1].children

      set = children[3,2].map {|x| x.children[1,4]}
      weather = set[0].zip(set[1]).inject(nil) {|worst, x|
        (worst.nil? || worst[1].text.to_i < x[1].text.to_i) ? x : z
      }
      {
        :day => date,
        :date => date,
        :url => weather[0].children[0]['src'],
        :weather => weather[0].children[1].text,
      }
    }
  end

  def self.scrape_sixday(doc)
    doc.css('div#sixday table').map {|node|
      children = node.children
      # msn html has no closed angle bracket <table class="t3" <tr> ...
      children[1,5].zip(children[7].children[1,5]).each do |child|
        {
          :day => child[0].text,
          :date => child[0].text,
          :url => child[1].children[0]['src'],
          :weather => child[1].children[1].text,
        }
      end
    }
  end
end

__END__
puts MSNWeather.weather('香港')
puts MSNWeather.weather('バンクーバー')
puts MSNWeather.weather('北京')
puts MSNWeather.weather('ソウル')
puts MSNWeather.weather('バンコク')

