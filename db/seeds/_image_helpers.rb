# db/seeds/_image_helpers.rb
require "open-uri"

module SeedImageHelpers
  module_function

  def attach_from_url!(record, url, filename: nil, content_type: nil)
    return if url.to_s.strip.empty?

    uri = URI.parse(url)
    fname = filename || File.basename(uri.path.presence || "image.jpg")
    ctype = content_type || guess_content_type(fname)

    URI.open(uri, read_timeout: 15, open_timeout: 10) do |io|
      record.images.attach(io: io, filename: fname, content_type: ctype)
    end
  rescue => e
    warn "[seed] failed to attach #{url} to #{record.class}(id=#{record.id}): #{e.class} #{e.message}"
  end

  def guess_content_type(filename)
    case File.extname(filename).downcase
    when ".png" then "image/png"
    when ".webp" then "image/webp"
    when ".gif" then "image/gif"
    else "image/jpeg"
    end
  end
end
