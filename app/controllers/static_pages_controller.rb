# frozen_string_literal: true

module Storefront
  class StaticPagesController < ApplicationController
    # GET /storefront/about
    def about; end

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
        return render :contact, status: :unprocessable_content
      end

      # ContactMailer.contact(**attrs.slice(:name, :email).merge(subject: attrs[:subject], message: attrs[:message])).deliver_later
      flash[:notice] = "Thanks for reaching out! We’ll get back to you shortly."
      redirect_to storefront_contact_path(anchor: "contact-form")
    end

    # Static pages
    def shipping_returns; end
    def store_policy;     end          # canonical
    def policies;         render :store_policy end  # back-compat alias
    def payments;         end
    def faq;              end
    def privacy_policy;   end
    def terms;            end

    private

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
