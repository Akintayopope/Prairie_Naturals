ActiveAdmin.register Category do
  permit_params :name

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :products_count if Category.column_names.include?("products_count")
    actions
  end

  show do
    attributes_table do
      row :name
      row :slug
      row :created_at
      row :updated_at
    end
    panel "Products" do
      table_for resource.products.limit(50) do
        column(:name) { |p| link_to p.name, admin_product_path(p) }
        column :price
        column :stock
        column "Image" do |p|
          image_tag url_for(p.images.first.variant(resize_to_limit: [60, 60])) if p.images.attached?
        end
      end
    end
  end
end
