FactoryBot.define do
  factory :user do
    email_address { "user@example.com" }
    password { "password" }
    password_confirmation { "password" }
  end
end
