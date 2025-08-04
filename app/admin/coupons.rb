ActiveAdmin.register Coupon do
  permit_params :code, :discount_amount, :expires_at

  index do
    selectable_column
    id_column
    column :code
    column :discount_amount
    column :expires_at
    actions
  end

  filter :code
  filter :discount_amount
  filter :expires_at

  form do |f|
    f.inputs do
      f.input :code
      f.input :discount_amount
      f.input :expires_at, as: :datepicker
    end
    f.actions
  end
end
