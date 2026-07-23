require 'rails_helper'

RSpec.describe Rummy::Deck, type: :model do
  it 'has 52 cards when created' do
    deck = described_class.new
    expect(deck.cards.count).to eq 52
  end

  it 'builds Rummy::Card instances' do
    deck = described_class.new
    expect(deck.cards).to all(be_a(Rummy::Card))
  end
end
