ActiveAdmin.register Product do
  permit_params :name, :description, :price, :stock, :category_id, :image

  index do
    selectable_column
    id_column
    column :name
    column :description
    column :price
    column :stock
    column :category
    column :created_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :description
      f.input :price
      f.input :stock
      f.input :category
      f.input :image, as: :file
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :description
      row :price
      row :stock
      row :category
      row :image do |product|
        if product.image.attached?
          image_tag url_for(product.image), style: "max-width: 100px;"
        end
      end
    end
  end
end
