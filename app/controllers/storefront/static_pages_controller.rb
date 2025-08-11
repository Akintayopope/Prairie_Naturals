# app/controllers/storefront/static_pages_controller.rb
module Storefront
  class StaticPagesController < ApplicationController
    before_action :prepare_prefill, only: :contact

    def about; end
    def contact; end
    def shipping_returns; end
    def policies; end
    def faq; end
    def payments; end

    def contact_submit
      return bot_ok if honeypot_filled?
      return throttle_ok if throttled?

      unless valid_contact_params?
        return redirect_to storefront_contact_path(anchor: "contact-form"),
                           alert: "Please enter your name, a valid email, and a message."
      end

      if too_many_links?(contact_params[:message])
        return redirect_to storefront_contact_path(anchor: "contact-form"),
                           alert: "Please remove links and try again."
      end

      # TODO: Hook up mailer
      # ContactMailer.with(contact_params).submit.deliver_later

      stamp_throttle!
      redirect_to storefront_contact_path, notice: "Message sent. We’ll reply within 1–2 business days."
    rescue => e
      Rails.logger.error("[ContactSubmit] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      redirect_to storefront_contact_path(anchor: "contact-form"),
                  alert: "Sorry—something went wrong. Please try again."
    end

    private

    def prepare_prefill
      @prefill = {
        name:  current_user&.name,
        email: current_user&.email
      }
    end

    def contact_params
      @contact_params ||= begin
        permitted = params.permit(:name, :email, :subject, :message)
        {
          name:    permitted[:name].to_s.strip,
          email:   permitted[:email].to_s.strip,
          subject: (permitted[:subject].presence || "General inquiry").to_s.strip,
          message: permitted[:message].to_s.strip
        }
      end
    end

    def valid_contact_params?
      contact_params[:name].present? &&
        contact_params[:message].present? &&
        contact_params[:email].match?(URI::MailTo::EMAIL_REGEXP)
    end

    def honeypot_filled?
      params[:company].to_s.strip.present?
    end

    def bot_ok
      redirect_to storefront_contact_path, notice: "Thanks! We’ll be in touch."
    end

    def throttled?
      last = session[:last_contact_at].to_i
      last.positive? && (Time.now.to_i - last) < 20
    end

    def throttle_ok
      wait = 20 - (Time.now.to_i - session[:last_contact_at].to_i)
      redirect_to storefront_contact_path(anchor: "contact-form"),
                  alert: "Please wait #{wait}s before sending another message."
    end

    def stamp_throttle!
      session[:last_contact_at] = Time.now.to_i
    end

    def too_many_links?(text)
      text.scan(%r{https?://}i).size > 3
    end
  end
end
