ActiveAdmin.register Product do
  permit_params :name, :description, :price, :stock, :category_id

  index do
    selectable_column
    id_column
    column :name
    column :price
    column :stock
    column :category
    column :created_at
    actions
  end

  filter :name
  filter :category
  filter :price
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :description
      f.input :price
      f.input :stock
      f.input :category
    end
    f.actions
  end
end
