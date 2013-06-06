require 'mini_magick'
require 'net/http'

module StringToGyazo
  $-v, v = nil, $-v
  refine String do
    $-v = v
    def to_gyazo
      out = StringIO.new

      image = MiniMagick::Image.open('image/tenkigirls.png')

      y = 20
      self.lines.each do |line|
        image.combine_options do |c|
          c.pointsize '10'
          c.draw %Q{text 80,#{y} "#{line.strip}"}
          c.font './font/uzura.ttf'
          c.fill('#000000')
        end
        y += 12
      end

      image.write(out)

      boundary = '----BOUNDARYBOUNDARY----'
      id = "foo"

      data = <<EOF
--#{boundary}\r
content-disposition: form-data; name="id"\r
\r
#{id}\r
--#{boundary}\r
content-disposition: form-data; name="imagedata"; filename="gyazo.com"\r
\r
#{out.string}\r
--#{boundary}--\r
EOF

      header = {
        'Content-Length' => data.length.to_s,
        'Content-type' => "multipart/form-data; boundary=#{boundary}",
        'User-Agent' => 'Gyazo/1.0',
      }
      env = ENV['http_proxy']
      if env
        uri = URI(env)
        proxy_host, proxy_port = uri.host, uri.port
      else
        proxy_host, proxy_port = nil, nil
      end
      Net::HTTP::Proxy(proxy_host, proxy_port).start('gyazo.com', 80) do |http|
        http.post('/upload.cgi', data, header).response.body + '.png'
      end
    end
  end
end
