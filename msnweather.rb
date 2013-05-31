# -*- coding: utf-8 -*-
require 'nokogiri'
require 'open-uri'

module MSNWeather
  TOP_URL = 'http://weather.jp.msn.com/'
  REGEX_URL = Regexp.escape('http://weather.jp.msn.com/local.aspx?wealocations=wc:')


  def weather(options)
    self.init_url if @url_hash.nil?

    return unless @url_hash.key? options[:city]

    doc = Nokogiri::HTML(open(@url_hash[options[:city]]))
    self.scrape_foreigner(doc)
  end

  module_function :weather

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

  # 市区町村
  def self.scrape_japanese_area(doc)
  end

  # 代表都市
  def self.scrape_japanese_spot(doc)
    twoday = []
    doc.css('div#twoday > div > div > div:first-child').each do |node|
      children = node.children
      twoday << {
        :day => children[0].text,
        :date => children[0].text,
        :url => children[1]['src'],
        :weather => children[2].text,
      }
    end

    return if twoday.empty?

    sixday = self.scrape_sixday(doc)

    twoday + sixday
  end

  def self.scrape_sixday(doc)
    sixday = []
    doc.css('div#sixday table').each do |node|
      set = node.children[1,2].map { |c| c.children[1,5] }
      set[0].zip(set[1]).each do |child|
        sixday << {
          :day => child[0].text,
          :date => child[0].text,
          :url => child[1]['src'],
          :weather => child[2].text,
        }
      end
    end

    sixday
  end

end

__END__
puts MSNWeather.weather(:city => '香港')
puts MSNWeather.weather(:city => 'バンクーバー')
puts MSNWeather.weather(:city => '北京')
puts MSNWeather.weather(:city => 'ソウル')
puts MSNWeather.weather(:city => 'バンコク')

