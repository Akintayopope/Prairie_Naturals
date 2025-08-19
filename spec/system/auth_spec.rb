require 'rails_helper'

RSpec.describe "Auth", type: :system do
  def visit_signup
    visit "/users/sign_up" rescue visit("/signup")
  end

  def visit_login
    visit "/users/sign_in" rescue visit("/login")
  end

  # Fill the two password fields on the signup form.
  def set_signup_passwords(pass)
    within(first('form')) do
      # Prefer Devise ids if present
      if page.has_selector?('#user_password', wait: 0)
        fill_in 'user_password', with: pass
      elsif page.has_selector?('input[name="user[password]"]', wait: 0)
        find('input[name="user[password]"]', visible: :all).set(pass)
      else
        # fallback: first password input on the page
        all('input[type="password"]', visible: :all)[0]&.set(pass)
      end

      if page.has_selector?('#user_password_confirmation', wait: 0)
        fill_in 'user_password_confirmation', with: pass
      elsif page.has_selector?('input[name="user[password_confirmation]"]', wait: 0)
        find('input[name="user[password_confirmation]"]', visible: :all).set(pass)
      else
        # fallback: second password input on the page
        all('input[type="password"]', visible: :all)[1]&.set(pass)
      end
    end
  end

  # Fill the single password field on the login form.
  def set_login_password(pass)
    within(first('form')) do
      if page.has_selector?('#user_password', wait: 0)
        fill_in 'user_password', with: pass
      elsif page.has_selector?('input[name="user[password]"]', wait: 0)
        find('input[name="user[password]"]', visible: :all).set(pass)
      else
        first('input[type="password"]', visible: :all)&.set(pass)
      end
    end
  end

  it "signs up, logs out, and logs back in (happy path)" do
    visit_signup

    within(first('form')) do
      fill_in "Username", with: "test_user_123" rescue nil
      # Email label seems present from your output
      fill_in "Email", with: "test_user@example.com" rescue find('input[type="email"]', visible: :all)&.set("test_user@example.com")

      set_signup_passwords("User123!User123!")

      # Your form requires address fields
      fill_in "Address line 1", with: "123 Main St" rescue nil
      fill_in "City", with: "Winnipeg" rescue nil
      (fill_in "Postal Code", with: "R3C 1A5" rescue fill_in("Postal", with: "R3C 1A5") rescue nil)
      (select "Manitoba", from: "Province" rescue select("Manitoba", from: /Province/i) rescue nil)

      # Submit (Sign up / Create account)
      (first(:button, /sign up|create account/i, minimum: 1)&.click) || click_button("Sign up")
    end

    expect(page).not_to have_content(/errors prohibited this user from being saved/i)
    expect(page).to have_content(/welcome|signed in|account|dashboard/i)

    # Log out (Log out / Logout)
    (click_link("Log out", exact: false) rescue click_link("Logout", exact: false) rescue nil)
    expect(page).to have_content(/log in|sign in|signed out/i)

    # Log back in
    visit_login
    within(first('form')) do
      fill_in "Email", with: "test_user@example.com" rescue find('input[type="email"]', visible: :all)&.set("test_user@example.com")
      set_login_password("User123!User123!")
      (first(:button, /log in|sign in/i, minimum: 1)&.click) || click_button("Log in")
    end

    expect(page).to have_content(/welcome|signed in|account|dashboard/i)
  end

  it "shows errors for bad signup (unhappy path)" do
    visit_signup
    within(first('form')) do
      fill_in "Email", with: "bademail" rescue find('input[type="email"]', visible: :all)&.set("bademail")
      set_signup_passwords("short")
      (first(:button, /sign up|create account/i, minimum: 1)&.click) || click_button("Sign up")
    end
    expect(page).to have_content(/error|invalid|mismatch|prohibited this user/i)
  end

  it "shows feedback for wrong password (unhappy path)" do
    User.find_or_create_by!(email: "user@prairienaturals.com") do |u|
      u.username = "demo_user" if u.respond_to?(:username=)
      u.password = "User123!User123!"
      u.password_confirmation = "User123!User123!"
    end

    visit_login
    within(first('form')) do
      fill_in "Email", with: "user@prairienaturals.com" rescue find('input[type="email"]', visible: :all)&.set("user@prairienaturals.com")
      set_login_password("wrongpassword")
      (first(:button, /log in|sign in/i, minimum: 1)&.click) || click_button("Log in")
    end
    expect(page).to have_content(/invalid|incorrect|error/i)
  end
end
