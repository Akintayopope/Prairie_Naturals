class Stripe::WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig = request.env["HTTP_STRIPE_SIGNATURE"]
    secret = ENV["STRIPE_WEBHOOK_SECRET"]

    event =
      (
        if secret.present?
          Stripe::Webhook.construct_event(payload, sig, secret)
        else
          Stripe::Event.construct_from(JSON.parse(payload))
        end
      )

    if event["type"] == "checkout.session.completed"
      s = event["data"]["object"]
      order =
        Order.find_by(id: s.dig("metadata", "order_id")) ||
          Order.find_by(stripe_session_id: s["id"])
      if order && s["payment_status"] == "paid"
        order.update!(status: "paid", stripe_payment_id: s["payment_intent"])
      end
    end
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  end
end
