ActiveAdmin.register Category do
  permit_params :name

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  includes :products
  config.sort_order = "name_asc"

  filter :name
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    if Category.column_names.include?("products_count")
      column("Products") { |c| c.products_count }
    else
      column("Products") { |c| c.products.size }
    end
    column :created_at
    actions
  end

  csv do
    column :id
    column :name
    column(:products_count) do |c|
      if Category.column_names.include?("products_count")
        c.products_count
      else
        c.products.size
      end
    end
    column :created_at
    column :updated_at
  end

  # Show
  show do
    attributes_table do
      row :name
      row :slug if resource.respond_to?(:slug)
      row :created_at
      row :updated_at
    end

    panel "Products" do
      products =
        resource
          .products
          .with_attached_images
          .order(created_at: :desc)
          .limit(50)

      table_for products do
        column("Name") { |p| auto_link(p, p.name) } # namespace-agnostic link
        column("Price") { |p| number_to_currency(p.price || 0) }
        column("Stock") { |p| p.respond_to?(:stock) ? p.stock : "-" }
        column("Image") do |p|
          if p.images.attached?
            img = p.images.first
            begin
              image_tag url_for(img.variant(resize_to_limit: [60, 60]))
            rescue StandardError
              image_tag url_for(img)
            end
          else
            status_tag "No image", :warning
          end
        end
      end

      ns = ActiveAdmin.application.default_namespace
      index_helper = "#{ns}_products_path"
      if helpers.respond_to?(index_helper)
        div { link_to "View all products", send(index_helper), class: "button" }
      end
    end
  end

  sidebar "Category Stats", only: :show do
    ul do
      li "Total Products: #{resource.products.size}"
      if resource.respond_to?(:created_at)
        li "Created: #{l(resource.created_at, format: :short)}"
      end
      if resource.respond_to?(:updated_at)
        li "Updated: #{l(resource.updated_at, format: :short)}"
      end
    end
  end
end
