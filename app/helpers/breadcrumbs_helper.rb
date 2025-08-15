module BreadcrumbsHelper
  def breadcrumb_trail(record: nil)
    crumbs = [{ label: "Home", url: root_path }]

    if controller_path == "storefront/products"
      case action_name
      when "index"
        if @is_homepage
          # Home → Featured Products (homepage)
          crumbs << { label: "Featured Products", url: root_path }
        elsif defined?(@category) && @category.present?
          # Home → Category (filtered PLP)
          crumbs << { label: @category.name, url: storefront_products_path(category_id: @category.id) }
        else
          # Home → Products (unfiltered PLP)
          crumbs << { label: "Products", url: storefront_products_path }
        end

      when "show"
        product = record || @product
        if product&.category
          crumbs << { label: product.category.name, url: storefront_products_path(category_id: product.category_id) }
        else
          crumbs << { label: "Products", url: storefront_products_path }
        end
        crumbs << { label: product&.name.to_s, url: request.path }
      end

    else
      title = content_for?(:title) ? content_for(:title) : action_name.humanize
      crumbs << { label: title, url: request.path }
    end

    crumbs.first(3)
  end
end
