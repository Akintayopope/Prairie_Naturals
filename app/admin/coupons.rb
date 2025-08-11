# app/admin/coupons.rb
ActiveAdmin.register Coupon do
  # ---------- strong params ----------
  # uses_count is system-managed; no manual edits
  permit_params :code, :discount_type, :value, :starts_at, :ends_at, :max_uses, :active

  # ---------- scopes ----------
  scope :all, default: true
  scope("Active now") { |s| s.active_now }
  scope("Inactive")   { |s| s.where(active: false) }
  scope("Scheduled")  { |s| s.where("starts_at > ?", Time.current) }
  scope("Expired")    { |s| s.where("ends_at IS NOT NULL AND ends_at < ?", Time.current) }

  # ---------- filters (Ransack) ----------
  filter :code_cont,        label: "Code contains"
  filter :discount_type_eq, as: :select, collection: -> { Coupon.discount_types.keys }
  filter :value_gteq,       label: "Min value"
  filter :value_lteq,       label: "Max value"
  filter :active
  filter :starts_at
  filter :ends_at
  filter :created_at

  # ---------- quick actions (top-right) ----------
  action_item :new_percent_10, only: :index do
    link_to "Create SAVE10", new_resource_path(code: "SAVE10", discount_type: :percent, value: 10)
  end
  action_item :new_amount_5, only: :index do
    link_to "Create WELCOME5", new_resource_path(code: "WELCOME5", discount_type: :amount, value: 5.00)
  end
  action_item :activate_all_scheduled_today, only: :index do
    link_to "Enable all starting today",
            activate_today_admin_coupons_path,
            method: :post,
            data: { turbo: false, confirm: "Enable all coupons that start today?" }
  end
  action_item :deactivate_all_active, only: :index do
    link_to "Disable all active",
            deactivate_all_admin_coupons_path,
            method: :post,
            data: { turbo: false, confirm: "Disable ALL active coupons?" }
  end

  # ---------- batch actions ----------
  batch_action :activate do |ids|
    batch_action_collection.where(id: ids).update_all(active: true)
    redirect_back fallback_location: collection_path, notice: "Activated #{ids.size} coupon(s)."
  end

  batch_action :deactivate do |ids|
    batch_action_collection.where(id: ids).update_all(active: false)
    redirect_back fallback_location: collection_path, notice: "Deactivated #{ids.size} coupon(s)."
  end

  batch_action :reset_uses, confirm: "Reset uses_count to 0 for selected?" do |ids|
    batch_action_collection.where(id: ids).update_all(uses_count: 0)
    redirect_back fallback_location: collection_path, notice: "Reset uses for #{ids.size} coupon(s)."
  end

  # ---------- index table ----------
  index do
    selectable_column
    id_column
    column :code
    column("Type")   { |c| status_tag c.discount_type.humanize, class: (c.percent? ? "ok" : "warning") }
    column("Value")  { |c| c.percent? ? "#{c.value.to_i}%" : number_to_currency(c.value) }
    column("Active?") { |c|
      status_tag(c.active_now? ? "Yes" : "No", class: c.active_now? ? "ok" : "error")
    }
    column("Window") { |c|
      start = c.starts_at&.strftime("%Y-%m-%d")
      stop  = c.ends_at&.strftime("%Y-%m-%d")
      [ start, stop ].compact.join(" → ").presence || "—"
    }
    column("Usage")  { |c| c.usage_string }
    actions defaults: true do |c|
      links = []
      links << link_to(c.active ? "Disable" : "Enable",
                       toggle_active_admin_coupon_path(c),
                       method: :put, data: { turbo: false })
      links << link_to("Use +1",
                       bump_use_admin_coupon_path(c),
                       method: :put, data: { turbo: false })
      links << link_to("Reset uses",
                       reset_uses_admin_coupon_path(c),
                       method: :put, data: { turbo: false, confirm: "Reset uses_count to 0?" })
      safe_join(links, " | ".html_safe)
    end
  end

  # ---------- CSV export ----------
  csv do
    column :id
    column :code
    column(:discount_type) { |c| c.discount_type }
    column(:value)         { |c| c.percent? ? "#{c.value.to_i}%" : c.value }
    column :active
    column :starts_at
    column :ends_at
    column :uses_count
    column :max_uses
    column :created_at
    column :updated_at
  end

  # ---------- show ----------
  show do
    attributes_table do
      row :code
      row(:discount_type) { |c| c.discount_type.humanize }
      row("Value")        { |c| c.percent? ? "#{c.value.to_i}%" : number_to_currency(c.value) }
      row :active
      row :starts_at
      row :ends_at
      row :uses_count
      row :max_uses
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  # ---------- form ----------
  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :code, input_html: { placeholder: "e.g. SAVE10" }
      f.input :discount_type, as: :select, collection: Coupon.discount_types.keys, include_blank: false
      f.input :value, hint: "If percent: 1–100. If amount: dollars (e.g., 5.00)"
      f.input :active
      f.input :starts_at, as: :datetime_picker
      f.input :ends_at,   as: :datetime_picker
      f.input :max_uses, hint: "Leave blank for unlimited"
      # uses_count omitted on purpose
    end
    f.actions
  end

  # ---------- sidebar help ----------
  sidebar "How values work", only: %i[new edit show] do
    para "• Percent coupons: value must be 1–100."
    para "• Amount coupons: value is currency (e.g., 5.00)."
    para "• Active now means: active = true AND within start/end window."
  end

  # ---------- member actions ----------
  member_action :toggle_active, method: :put do
    resource.update!(active: !resource.active)
    redirect_back fallback_location: admin_coupon_path(resource),
                  notice: "Coupon #{resource.active ? 'enabled' : 'disabled'}."
  end

  member_action :bump_use, method: :put do
    resource.increment!(:uses_count)
    redirect_back fallback_location: admin_coupon_path(resource),
                  notice: "Incremented uses for #{resource.code}."
  end

  member_action :reset_uses, method: :put do
    resource.update!(uses_count: 0)
    redirect_back fallback_location: admin_coupon_path(resource),
                  notice: "Reset uses for #{resource.code}."
  end

  # ---------- collection actions ----------
  collection_action :activate_today, method: :post do
    count = Coupon.where(active: false)
                  .where(starts_at: Time.current.beginning_of_day..Time.current.end_of_day)
                  .update_all(active: true)
    redirect_back fallback_location: admin_coupons_path,
                  notice: "Enabled #{count} coupon(s) starting today."
  end

  collection_action :deactivate_all, method: :post do
    count = Coupon.where(active: true).update_all(active: false)
    redirect_back fallback_location: admin_coupons_path,
                  alert: "Disabled #{count} active coupon(s)."
  end
end
