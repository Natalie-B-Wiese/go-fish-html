require 'rails_helper'

RSpec.describe GoFish::Player, type: :model do
  let(:player) { described_class.new(1) }

  describe '#add_card' do
    it 'adds a card to the hand' do
      card1 = Card.new('3', 'Diamonds')

      player.add_card(card1)
      expect(player.cards).to include(card1)
    end

    it 'will create a book if possible' do
      rank = 'A'
      %w[Hearts Spades Diamonds Clubs].each do |suit|
        player.add_card(Card.new(rank, suit))
      end

      expect(player.books).to_not be_empty
      expect(player.book_made?).to eq true
    end

    context 'when previously made a book' do
      let(:other_rank) { '5' }

      before do
        rank = 'A'
        %w[Hearts Spades Diamonds Clubs].each do |suit|
          player.add_card(Card.new(rank, suit))
        end
      end

      it 'resets book variable when book impossible' do
        player.add_card(Card.new(other_rank, 'Hearts'))
        expect(player.book_made?).to eq false
      end
    end
  end

  describe '#add_cards' do
    it 'adds multiple cards' do
      card1 = Card.new('3', 'Diamonds')
      card2 = Card.new('5', 'Hearts')

      player.add_cards([card1, card2])
      expect(player.cards).to include(card1)
      expect(player.cards).to include(card2)
    end

    it 'will create a book if possible' do
      rank = 'A'
      cards_to_add = []
      %w[Hearts Spades Diamonds Clubs].each do |suit|
        cards_to_add.push(Card.new(rank, suit))
      end

      player.add_cards(cards_to_add)

      expect(player.books).to_not be_empty
      expect(player.book_made?).to eq true
    end

    context 'when previously made a book' do
      let(:other_rank) { '5' }

      before do
        rank = 'A'
        cards_to_add = []
        %w[Hearts Spades Diamonds Clubs].each do |suit|
          cards_to_add.push(Card.new(rank, suit))
        end

        player.add_cards(cards_to_add)
      end

      it 'resets book variable when book not possible' do
        player.add_cards([Card.new(other_rank, 'Hearts')])
        expect(player.book_made?).to eq false
      end
    end
  end

  describe '#card_ranks' do
    it 'returns an array of ranks' do
      ranks = %w[3 5 A]
      ranks.each do |rank|
        player.add_card(Card.new(rank, 'Hearts'))
      end

      expect(player.card_ranks).to eq ranks
    end

    it 'ignores duplicates' do
      ranks = %w[3 3 5]
      ranks.each do |rank|
        player.add_card(Card.new(rank, 'Hearts'))
      end

      expect(player.card_ranks).to eq ranks.uniq
    end
  end

  describe '#take_cards_with_rank' do
    let(:card1) { Card.new('A', 'Diamonds') }
    let(:card2) { Card.new('2', 'Diamonds') }
    let(:card3) { Card.new('3', 'Diamonds') }

    let(:card2_same) { Card.new('2', 'Hearts') }

    before do
      player.add_cards([card1, card2, card3, card2_same])
    end

    context 'when player has one of the specified card' do
      let(:card_to_take) { card3 }
      it 'returns an array with a single card' do
        result = player.take_cards_with_rank(card_to_take.rank)
        expect(result).to eq [card_to_take]
      end

      it 'removes the card from the player' do
        player.take_cards_with_rank(card_to_take.rank)
        expect(player.cards).to_not include(card_to_take)
      end

      it 'works with non numerical cards' do
        result = player.take_cards_with_rank(card1.rank)
        expect(result).to eq [card1]
        expect(player.cards).to_not include(card1)
      end
    end

    context 'when player has more than one of the specified card' do
      it 'returns an array with all cards' do
        result = player.take_cards_with_rank('2')
        expect(result).to include(card2, card2_same)
      end

      it 'removes all the matching rank cards from the player' do
        player.take_cards_with_rank('2')
        expect(player.cards).to_not include(card2, card2_same)
      end
    end

    context 'when player does not have the specified card' do
      let(:nonexistant_rank) { 'K' }
      it 'returns empty array' do
        result = player.take_cards_with_rank(nonexistant_rank)
        expect(result).to be_empty
      end

      it 'does not remove any cards from player' do
        num_cards_before = player.cards.length
        player.take_cards_with_rank(nonexistant_rank)
        expect(player.cards.length).to eq num_cards_before
      end
    end
  end

  describe '#biggest_book_value' do
    context 'when there are no books' do
      before do
        player.books = []
      end

      it 'returns 0' do
        result = player.biggest_book_value
        expect(result).to eq 0
      end
    end

    context 'when there is 1 book' do
      let(:biggest_rank) { '5' }
      let(:biggest_value) { Card.rank_to_value(biggest_rank) }

      before do
        player.books = [GoFish::Book.new(biggest_rank)]
      end

      it 'returns that book value' do
        result = player.biggest_book_value
        expect(result).to eq biggest_value
      end
    end

    context 'when there are multiple books' do
      let(:biggest_rank) { 'A' }
      let(:biggest_value) { Card.rank_to_value(biggest_rank) }

      before do
        player.books = [GoFish::Book.new('2'), GoFish::Book.new(biggest_rank), GoFish::Book.new('8')]
      end

      it 'returns the biggest book value' do
        result = player.biggest_book_value
        expect(result).to eq biggest_value
      end
    end
  end

  describe '#out_of_cards?' do
    it 'returns true when player has no cards' do
      expect(player).to be_out_of_cards
    end

    it 'returns false when player has cards' do
      player.add_card(Card.new('A', 'Spades'))
      expect(player).to_not be_out_of_cards
    end
  end

  describe '#includes_card_with_rank?' do
    context 'when player does not have cards' do
      it 'returns false' do
        expect(player.includes_card_with_rank?('2')).to eq false
      end
    end

    context 'when player has cards' do
      let(:rank_have) { 'A' }
      let(:rank_not_have) { '3' }
      before do
        player.add_card(Card.new(rank_have, 'Spades'))
      end

      it 'returns false when player does not include a card with the rank' do
        expect(player.includes_card_with_rank?(rank_not_have)).to eq false
      end

      it 'returns true when player does include a card with the rank' do
        expect(player.includes_card_with_rank?(rank_have)).to eq true
      end
    end
  end
end
