# app/controllers/storefront/static_pages_controller.rb
# frozen_string_literal: true

module Storefront
  class StaticPagesController < ApplicationController
    # GET /storefront/about
    def about
      render_static("about")
    end

    # GET /storefront/contact
    def contact
      @prefill = {
        name:  (current_user&.respond_to?(:full_name) ? current_user.full_name : current_user&.try(:name)),
        email: current_user&.email
      }.compact
      @contact = ContactMessage.new
      @errors  = []
    end

    # POST /storefront/contact
    def contact_submit
      return head :ok if params[:company].present? # honeypot

      attrs    = extract_contact_params
      @contact = ContactMessage.new(attrs)
      @errors  = []

      unless @contact.valid?
        @errors  = @contact.errors.full_messages
        @prefill = { name: attrs[:name], email: attrs[:email] }
        flash.now[:alert] = @errors.join(". ")
        return render :contact, status: :unprocessable_entity
      end

      # ContactMailer.contact(**attrs.slice(:name, :email).merge(subject: attrs[:subject], message: attrs[:message])).deliver_later
      flash[:notice] = "Thanks for reaching out! We’ll get back to you shortly."
      redirect_to storefront_contact_path(anchor: "contact-form")
    end

    # -------- Static pages (named routes) --------
    def shipping_returns  = render_static("shipping_returns")
    def store_policy      = render_static("store_policy")        # canonical
    def policies          = render_static("store_policy")        # back-compat alias
    def payments          = render_static("payments")
    def faq               = render_static("faq")
    def privacy_policy    = render_static("privacy_policy")
    def terms             = render_static("terms")

    # -------- Optional dynamic route: GET /storefront/:slug --------
    # Add route:
    #   scope :storefront, module: :storefront do
    #     get "/:slug", to: "static_pages#show", as: :storefront_page
    #   end
    def show
      render_static(params[:slug].to_s)
    end

    private

    # Prefer DB-managed StaticPage; fall back to ERB template if present
    def render_static(slug)
      if (page = StaticPage.find_by(slug: slug))
        @title = page.title
        @body  = page.body
        return render template: "storefront/static_pages/dynamic"
      end

      template = "storefront/static_pages/#{slug}"
      if lookup_context.exists?(template)
        return render template
      end

      render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
    end

    # Supports either scoped (:contact_message[...]) or unscoped params (:name, etc.)
    def extract_contact_params
      if params[:contact_message].is_a?(ActionController::Parameters)
        p = params.require(:contact_message).permit(:name, :email, :message, :subject)
        {
          name:    p[:name].to_s.strip,
          email:   p[:email].to_s.strip,
          message: p[:message].to_s.strip,
          subject: (p[:subject].presence || "Website contact")
        }
      else
        {
          name:    params[:name].to_s.strip,
          email:   params[:email].to_s.strip,
          message: params[:message].to_s.strip,
          subject: (params[:subject].presence || "Website contact")
        }
      end
    end
  end
end
