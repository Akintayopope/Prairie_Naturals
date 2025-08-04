ActiveAdmin.register Order do
  permit_params :user_id, :address_id, :subtotal, :tax, :total, :status, :shipping_name, :shipping_address, :province

  index do
    selectable_column
    id_column
    column :user
    column :address
    column :status
    column :subtotal
    column :tax
    column :total
    column :created_at
    actions
  end

  filter :user
  filter :status
  filter :created_at
  filter :total

  form do |f|
    f.inputs do
      f.input :user
      f.input :address
      f.input :status, as: :select, collection: Order.statuses.keys
      f.input :subtotal
      f.input :tax
      f.input :total
      f.input :shipping_name
      f.input :shipping_address
      f.input :province
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :user
      row :address
      row :status
      row :subtotal
      row :tax
      row :total
      row :shipping_name
      row :shipping_address
      row :province
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
