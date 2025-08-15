# app/admin/products.rb
ActiveAdmin.register Product do
  # Strong params
  permit_params :name, :description, :price, :stock, :rating, :link, :category_id, images: []

  # FriendlyId lookup (if enabled)
  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  # Avoid N+1s
  includes :category, images_attachments: :blob

  # Filters
  filter :name
  filter :category
  filter :price
  filter :created_at

  # Index with thumbnail
  index do
    selectable_column
    column "Image" do |p|
      next unless p.images.attached?
      img = p.images.first
      begin
        image_tag url_for(img.variant(resize_to_limit: [ 60, 60 ])), width: 60, height: 60
      rescue
        image_tag url_for(img), width: 60, height: 60
      end
    end
    column :name
    column(:category) { |p| p.category&.name || "—" }
    column :price
    column :stock
    actions
  end

  # Show page with gallery + per-image delete
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
        ns = ActiveAdmin.application.default_namespace # e.g., :internal
        del_helper = "purge_image_#{ns}_product_path"

        div class: "flex flex-wrap gap-3" do
          resource.images.each do |img|
            div do
              begin
                concat image_tag url_for(img.variant(resize_to_limit: [ 300, 300 ]))
              rescue
                concat image_tag url_for(img)
              end
              concat " "
              concat link_to("Delete",
                             send(del_helper, resource, attachment_id: img.id),
                             method: :delete,
                             data: { confirm: "Delete this image?" },
                             class: "button")
            end
          end
        end
      else
        status_tag "No images"
      end
    end
  end

  # Form with multi-file upload and thumbnails + delete
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
      if f.object.images.attached?
        ns = ActiveAdmin.application.default_namespace
        del_helper = "purge_image_#{ns}_product_path"

        ul do
          f.object.images.each do |img|
            li do
              begin
                span image_tag url_for(img.variant(resize_to_limit: [ 120, 120 ]))
              rescue
                span image_tag url_for(img)
              end
              span " "
              span link_to("Delete",
                           send(del_helper, f.object, attachment_id: img.id),
                           method: :delete,
                           data: { confirm: "Delete this image?" })
            end
          end
        end
      end

      f.input :images, as: :file, input_html: { multiple: true, accept: "image/*" }
      para "Tip: hold Ctrl/Cmd to select multiple files."
    end

    f.actions
  end

  # Custom route to purge a single image (namespace-safe redirect)
  member_action :purge_image, method: :delete do
    attachment = resource.images.find(params[:attachment_id])
    attachment.purge
    redirect_back fallback_location: resource_path, notice: "Image deleted."
  end
end
