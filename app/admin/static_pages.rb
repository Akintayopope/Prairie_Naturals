ActiveAdmin.register StaticPage do
  ALLOWED_SLUGS = %w[
    about
    contact
    faq
    payments
    policies
    shipping_returns
    store_policy
    privacy_policy
    terms
  ].freeze

  permit_params :title, :slug, :body

  # Filters
  filter :title
  filter :slug, as: :select, collection: -> { ALLOWED_SLUGS }
  filter :created_at
  filter :updated_at

  # ---------- Quick action: create any missing pages ----------
  action_item :sync_defaults, only: :index do
    ns = ActiveAdmin.application.default_namespace
    path_helper = "sync_defaults_#{ns}_static_pages_path"
    if helpers.respond_to?(path_helper)
      link_to "Create missing default pages",
              send(path_helper),
              method: :post,
              data: {
                confirm: "Create records for any missing slugs?"
              }
    end
  end

  collection_action :sync_defaults, method: :post do
    created = 0
    ALLOWED_SLUGS.each do |slug|
      next if StaticPage.exists?(slug: slug)
      StaticPage.create!(
        slug: slug,
        title: slug.humanize.titleize,
        body:
          "<h2>#{slug.humanize.titleize}</h2>\n<p>Replace this content in Admin → Static Pages.</p>"
      )
      created += 1
    end
    redirect_to collection_path,
                notice:
                  (
                    if created.positive?
                      "Created #{created} page(s)."
                    else
                      "All pages already exist."
                    end
                  )
  end

  index do
    selectable_column
    column :title
    column :slug

    column "Preview" do |p|
      helper_name = :"storefront_#{p.slug}_path"
      if helpers.respond_to?(helper_name)
        link_to "View", send(helper_name), target: "_blank", rel: "noopener"
        # If you’ve added a dynamic fallback route: get '/storefront/:slug' => static_pages#show
      elsif helpers.respond_to?(:storefront_page_path)
        link_to "View",
                storefront_page_path(p.slug),
                target: "_blank",
                rel: "noopener"
      else
        fallback = "/storefront/#{p.slug.tr("_", "-")}"
        link_to "View", fallback, target: "_blank", rel: "noopener"
      end
    end

    actions
  end

  # ---------- Form ----------
  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :title
      f.input :slug,
              as: :select,
              collection: ALLOWED_SLUGS,
              include_blank: false,
              hint: "Choose which page this is (must be unique)."
      f.input :body, as: :text, input_html: { rows: 16 }
    end
    f.actions
  end

  # ---------- Show ----------
  show do
    attributes_table do
      row :title
      row :slug
      row(:body) { |record| div { raw(record.body) } }
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
