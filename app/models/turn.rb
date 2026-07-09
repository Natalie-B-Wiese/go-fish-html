class Turn
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Attributes::Normalization

  attr_accessor :opponent_user_id, :rank, :game, :requestor_user

  normalizes :opponent_user_id, with: ->(value) { value.to_i }
end
