class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :players
  has_many :games, through: :players

  validates :password, confirmation: { message: 'Passwords do not match' }, on: :create
  validates :password_confirmation, presence: true, on: :create

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, uniqueness: { case_sensitive: false, message: 'An account with that email already exists!' }

  validates :name, presence: true

  # turn empty string to nil
  normalizes :state, :country, with: ->(value) { value.presence }
end
