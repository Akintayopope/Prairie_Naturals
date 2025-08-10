ActiveAdmin.register StaticPage do
  permit_params :title, :slug, :body

  # Filters (right sidebar)
  filter :title
  filter :slug
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :title
    column :slug
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :title
      f.input :slug, hint: "Use 'about' or 'contact'"
      f.input :body, as: :text, input_html: { rows: 12 }
    end
    f.actions
  end

  show do
    attributes_table do
      row :title
      row :slug
      row(:body) { |p| pre p.body }
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
