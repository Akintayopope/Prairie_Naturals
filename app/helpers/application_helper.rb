module ApplicationHelper
  def cart_summary
    return { count: 0, total: 0.0 } unless session[:cart]

    products = Product.where(slug: session[:cart].keys)
    total = 0.0
    count = 0

    products.each do |product|
      quantity = session[:cart][product.slug].to_i
      total += product.price * quantity
      count += quantity
    end

    { count: count, total: total }
  end
end
