class DebugController < ApplicationController
  # if ApplicationController enforces login, bypass it here
  skip_before_action :authenticate_user!, raise: false

  def image_counts
    total         = Product.count
    with_url      = Product.where.not(image_url: [nil, ""]).count
    with_attached = Product.joins(:images_attachments).distinct.count

    sample = Product.limit(5).map do |p|
      "#{p.name} | url?=#{p.image_url.present?} | attached?=#{p.images.attached?}"
    end

    render plain: <<~TEXT
      Total products: #{total}
      With image_url: #{with_url}
      With ActiveStorage attached: #{with_attached}

      Sample:
      #{sample.join("\n")}
    TEXT
  end
end
