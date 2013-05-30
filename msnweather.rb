# -*- coding: utf-8 -*-
require 'nokogiri'
require 'open-uri'

module MSNWeather
  TOP_URL = 'http://weather.jp.msn.com/'
  REGEX_URL = Regexp.escape('http://weather.jp.msn.com/local.aspx?wealocations=wc:')


  def weather_of(city)
    self.init_url if @url_hash.nil?

    return unless @url_hash.key? city

    doc = Nokogiri::HTML(open(@url_hash[city]))
    self.scrape_foreigner(doc)
  end

  module_function :weather_of

  private
  def self.init_url
    @url_hash = {}
    doc = Nokogiri::HTML(open('http://weather.jp.msn.com/worldtop.aspx'))
    doc.css('div#browseWorld + div a').each do |node|
      @url_hash[node.text] = "#{node['href']}'&q=forecast:tenday'" if %r|^#{REGEX_URL}| =~ node['href']
    end
  end

  def self.scrape_foreigner(doc)
    anc = doc.css('div#localNav a').find { |node| /forecast:tenday$/ =~ node['href'] }

    return if anc.nil?

    tenday = []
    doc = Nokogiri::HTML(open(TOP_URL + anc['href']))
    doc.css('div#tenDay table').each do |node|
      tenday = node.children[3,10].map do |day|
        td1 = day.children[0].children
        td2 = day.children[1].children
        {
          :day => td1[0].text,
          :date => td1[1].text,
          :url => td2[0]['src'],
          :weather => td2[1].text,
        }
      end
    end

    tenday
  end
end

__END__
puts MSNWeather.weather_of('香港')
puts MSNWeather.weather_of('バンクーバー')
puts MSNWeather.weather_of('北京')
puts MSNWeather.weather_of('ソウル')
puts MSNWeather.weather_of('バンコク')

