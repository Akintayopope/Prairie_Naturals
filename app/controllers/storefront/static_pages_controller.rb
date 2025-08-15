# frozen_string_literal: true
module Storefront
  class StaticPagesController < ApplicationController
    skip_before_action :authenticate_user!, raise: false
    # GET /storefront/about
    def about; end

    # GET /storefront/contact
    def contact
      @prefill = {
        name:  (current_user&.respond_to?(:full_name) ? current_user.full_name : current_user&.try(:name)),
        email: current_user&.email
      }.compact
      @errors = []
    end

    # POST /storefront/contact
    def contact_submit
      return head :ok if params[:company].present? # Honeypot

      name    = params[:name].to_s.strip
      email   = params[:email].to_s.strip
      subject = params[:subject].presence || "Website contact"
      message = params[:message].to_s.strip

      @errors = []
      @errors << "Name is required"    if name.blank?
      @errors << "Email is required"   if email.blank?
      @errors << "Message is required" if message.blank?
      @errors << "Email looks invalid" if email.present? && (email !~ URI::MailTo::EMAIL_REGEXP)

      if @errors.any?
        flash.now[:alert] = @errors.join(". ")
        @prefill = { name:, email: }
        return render :contact, status: :unprocessable_content
      end

      # ContactMailer.contact(name:, email:, subject:, message:).deliver_later

      flash[:notice] = "Thanks for reaching out! We’ll reply within 1–2 business days."
      redirect_to storefront_contact_path(anchor: "contact-form")
    end

    # Static pages
    def shipping_returns; end
    def store_policy; end # <== This was missing
    def policies; render :store_policy end
    def payments; end
    def faq; end
    def privacy_policy; end
    def terms; end
  end
end
