class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :players
  has_many :games, through: :players

  validates :password, confirmation: { message: "Passwords do not match" }
  validates :password_confirmation, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, uniqueness: {case_sensitive: false, message: "An account with that email already exists!"}
end
