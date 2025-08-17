class DebugController < ApplicationController
  def image_counts
    total   = Product.count
    with_url = Product.where.not(image_url: [nil, ""]).count
    with_attached = Product.joins(:images_attachments).distinct.count

    sample = Product.limit(5).map do |p|
      {
        name: p.name,
        url_present: p.image_url.present?,
        attached: p.images.attached?
      }
    end

    render plain: <<~TEXT
      Total products: #{total}
      With image_url: #{with_url}
      With ActiveStorage attached: #{with_attached}

      Sample:
      #{sample.map { |s| "#{s[:name]} | url?=#{s[:url_present]} | attached?=#{s[:attached]}" }.join("\n")}
    TEXT
  end
end
