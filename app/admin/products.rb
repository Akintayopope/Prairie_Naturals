ActiveAdmin.register Product do
  # Strong params
  permit_params :name, :description, :price, :stock, :rating, :link, :category_id, images: []

  # Use FriendlyId in AA lookups
  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  # Filters (optional)
  filter :name
  filter :category
  filter :price
  filter :created_at

  # Index with thumbnail
  index do
    selectable_column
    column "Image" do |p|
      if p.images.attached?
        image_tag url_for(p.images.first.variant(resize_to_limit: [60, 60])), width: 60, height: 60
      end
    end
    column :name
    column(:category) { |p| p.category&.name }
    column :price
    column :stock
    actions
  end

  # Show page with gallery + quick delete links
  show do
    attributes_table do
      row :name
      row :category
      row :price
      row :stock
      row :rating
      row :link
      row :description
    end

    panel "Images" do
      if resource.images.attached?
        div class: "flex flex-wrap gap-3" do
          resource.images.each do |img|
            div do
              concat image_tag url_for(img.variant(resize_to_limit: [300, 300]))
              # delete button for each image
              concat(
                link_to "Delete",
                        purge_image_admin_product_path(resource, attachment_id: img.id),
                        method: :delete,
                        data: { confirm: "Delete this image?" },
                        class: "button"
                )
            end
          end
        end
      else
        status_tag "No images"
      end
    end
  end

  # Form with multi-file upload and category select
  form html: { multipart: true } do |f|
    f.semantic_errors
    f.inputs "Details" do
      f.input :name
      f.input :category, as: :select, collection: Category.order(:name), include_blank: false
      f.input :price
      f.input :stock
      f.input :rating
      f.input :link
      f.input :description, as: :text
    end

    f.inputs "Images" do
      # current images as thumbnails with delete links
      if f.object.images.attached?
        ul do
          f.object.images.each do |img|
            li do
              span image_tag url_for(img.variant(resize_to_limit: [120, 120]))
              span " "
              span link_to "Delete", purge_image_admin_product_path(f.object, attachment_id: img.id),
                             method: :delete, data: { confirm: "Delete this image?" }
            end
          end
        end
      end
      # upload new images (multiple)
      f.input :images, as: :file, input_html: { multiple: true, accept: "image/*" }
      para "Tip: hold Ctrl/Cmd to select multiple files."
    end

    f.actions
  end

  # Custom route to purge a single image
  member_action :purge_image, method: :delete do
    attachment = resource.images.find(params[:attachment_id])
    attachment.purge
    redirect_back fallback_location: admin_product_path(resource), notice: "Image deleted."
  end
end
