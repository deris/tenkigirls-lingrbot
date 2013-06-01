# coding: utf-8
require 'cairo'
require 'net/http'

module StringToGyazo
  $-v, v = nil, $-v
  refine String do
    $-v = v
    def to_gyazo
      out = StringIO.new
      image = Cairo::ImageSurface.from_png('image/tenkigirls.png')
      surface = Cairo::ImageSurface.new(image.width, image.height)
      context = Cairo::Context.new(surface)
      context.set_source(image, 0, 0)
      context.paint
      context.set_source_rgb(0, 0, 0)
      context.select_font_face('MS Gothic', 0, 0)
      context.font_size = 10
      y = 0
      self.lines.each do |line|
        context.move_to(80, 20 + y)
        context.show_text(line.strip)
        y += 12
      end
      surface.write_to_png(out)
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

      header ={
        'Content-Length' => data.length.to_s,
        'Content-type' => "multipart/form-data; boundary=#{boundary}",
        'User-Agent' => 'Gyazo/1.0',
      }
      env = ENV['http_proxy']
      if env then
        uri = URI(env)
        proxy_host, proxy_port = uri.host, uri.port
      else
        proxy_host, proxy_port = nil, nil
      end
      Net::HTTP::Proxy(proxy_host, proxy_port).start('gyazo.com', 80) do |http|
        res = http.post('/upload.cgi', data, header)
        return res.response.body
      end
    end
  end
end
