require 'rails_helper'

RSpec.describe Rummy::Meld, type: :model do
  describe '#initialize' do
    let(:ace) { Rummy::Card.new('A', 'Diamonds') }
    let(:three) { Rummy::Card.new('3', 'Diamonds') }
    let(:five) { Rummy::Card.new('5', 'Diamonds') }

    it 'sorts the cards by value' do
      meld = described_class.new([five, ace, three])

      expect(meld.cards).to eq [ace, three, five]
    end
  end

  describe '#valid?' do
    it 'is invalid if there are less than 3 cards' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts')
      ]

      meld = described_class.new(cards)

      expect(meld.valid?).to be false
    end

    it 'is valid when the cards form a set' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]

      meld = described_class.new(cards)

      expect(meld.valid?).to be true
    end

    it 'is valid when the cards form a run' do
      cards = [
        Rummy::Card.new('3', 'Diamonds'),
        Rummy::Card.new('4', 'Diamonds'),
        Rummy::Card.new('5', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.valid?).to be true
    end

    it 'is invalid when the cards form neither a set nor a run' do
      cards = [
        Rummy::Card.new('3', 'Diamonds'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('9', 'Clubs')
      ]

      meld = described_class.new(cards)

      expect(meld.valid?).to be false
    end
  end

  describe '#set?' do
    it 'is true for three cards of the same rank' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]

      meld = described_class.new(cards)

      expect(meld.set?).to be true
    end

    it 'is false for four of a kind with a mismatched rank mixed in' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs'),
        Rummy::Card.new('8', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.set?).to be false
    end

    it 'is false for a run' do
      cards = [
        Rummy::Card.new('3', 'Diamonds'),
        Rummy::Card.new('4', 'Diamonds'),
        Rummy::Card.new('5', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.set?).to be false
    end
  end

  describe '#run?' do
    it 'is true for an Ace-low run of the same suit' do
      cards = [
        Rummy::Card.new('A', 'Diamonds'),
        Rummy::Card.new('2', 'Diamonds'),
        Rummy::Card.new('3', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be true
    end

    it 'is true for a same-suit run given out of order' do
      cards = [
        Rummy::Card.new('3', 'Diamonds'),
        Rummy::Card.new('5', 'Diamonds'),
        Rummy::Card.new('4', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be true
    end

    it 'is false for consecutive ranks with a mismatched suit' do
      cards = [
        Rummy::Card.new('4', 'Diamonds'),
        Rummy::Card.new('5', 'Diamonds'),
        Rummy::Card.new('6', 'Hearts')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be false
    end

    it 'is false for a same-suit run that is not consecutive' do
      cards = [
        Rummy::Card.new('4', 'Diamonds'),
        Rummy::Card.new('6', 'Diamonds'),
        Rummy::Card.new('8', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be false
    end

    it 'is false for Q-K-A since Aces are low only' do
      cards = [
        Rummy::Card.new('Q', 'Diamonds'),
        Rummy::Card.new('K', 'Diamonds'),
        Rummy::Card.new('A', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be false
    end

    it 'is false for a set' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be false
    end
  end

  describe '#try_add_cards' do
    let(:three_spades) { Rummy::Card.new('3', 'Spades') }
    let(:four_spades) { Rummy::Card.new('4', 'Spades') }
    let(:five_spades) { Rummy::Card.new('5', 'Spades') }
    let(:six_spades) { Rummy::Card.new('6', 'Spades') }
    let(:seven_spades) { Rummy::Card.new('7', 'Spades') }
    let(:eight_spades) { Rummy::Card.new('8', 'Spades') }
    let(:nine_spades) { Rummy::Card.new('9', 'Spades') }
    let(:eight_hearts) { Rummy::Card.new('8', 'Hearts') }
    let(:run) { described_class.new([five_spades, six_spades, seven_spades]) }

    context 'when adding a matching card to a set' do
      let(:seven_hearts) { Rummy::Card.new('7', 'Hearts') }
      let(:seven_clubs) { Rummy::Card.new('7', 'Clubs') }
      let(:seven_diamonds) { Rummy::Card.new('7', 'Diamonds') }
      let(:set) { described_class.new([seven_spades, seven_hearts, seven_clubs]) }

      it 'returns non-nil' do
        expect(set.try_add_cards([seven_diamonds])).to_not be_nil
      end

      it 'adds the card to the meld' do
        set.try_add_cards([seven_diamonds])
        expect(set.cards).to include(seven_diamonds)
      end
    end

    context 'when adding a card to the high end of a run' do
      it 'returns non-nil' do
        expect(run.try_add_cards([eight_spades])).to_not be_nil
      end

      it 'adds the card in sorted order' do
        run.try_add_cards([eight_spades])
        expect(run.cards).to eq [five_spades, six_spades, seven_spades, eight_spades]
      end
    end

    context 'when adding a card to the low end of a run' do
      it 'returns non-nil' do
        expect(run.try_add_cards([four_spades])).to_not be_nil
      end

      it 'adds the card in sorted order' do
        run.try_add_cards([four_spades])
        expect(run.cards).to eq [four_spades, five_spades, six_spades, seven_spades]
      end
    end

    context 'when adding multiple out-of-order cards to a run' do
      it 'returns non-nil' do
        expect(run.try_add_cards([nine_spades, eight_spades])).to_not be_nil
      end

      it 'adds all the cards in sorted order' do
        run.try_add_cards([nine_spades, eight_spades])
        expect(run.cards).to eq [five_spades, six_spades, seven_spades, eight_spades, nine_spades]
      end
    end

    context 'when adding cards to both ends of a run at once' do
      it 'returns non-nil' do
        expect(run.try_add_cards([eight_spades, four_spades])).to_not be_nil
      end

      it 'adds all the cards in sorted order' do
        run.try_add_cards([eight_spades, four_spades])
        expect(run.cards).to eq [four_spades, five_spades, six_spades, seven_spades, eight_spades]
      end
    end

    context 'when adding a card of the wrong rank to a set' do
      let(:seven_hearts) { Rummy::Card.new('7', 'Hearts') }
      let(:seven_clubs) { Rummy::Card.new('7', 'Clubs') }
      let(:eight_diamonds) { Rummy::Card.new('8', 'Diamonds') }
      let(:set) { described_class.new([seven_spades, seven_hearts, seven_clubs]) }

      it 'returns nil' do
        expect(set.try_add_cards([eight_diamonds])).to be_nil
      end

      it 'does not change the meld' do
        set.try_add_cards([eight_diamonds])
        expect(set.cards).to eq [seven_spades, seven_hearts, seven_clubs]
      end
    end

    context 'when adding a valid rank card and a wrong card to a set' do
      let(:seven_hearts) { Rummy::Card.new('7', 'Hearts') }
      let(:seven_clubs) { Rummy::Card.new('7', 'Clubs') }
      let(:seven_diamonds) { Rummy::Card.new('7', 'Diamonds') }
      let(:eight_diamonds) { Rummy::Card.new('8', 'Diamonds') }
      let(:set) { described_class.new([seven_spades, seven_hearts, seven_clubs]) }

      it 'returns nil' do
        expect(set.try_add_cards([seven_diamonds, eight_diamonds])).to be_nil
      end

      it 'does not change the meld' do
        set.try_add_cards([seven_diamonds, eight_diamonds])
        expect(set.cards).to eq [seven_spades, seven_hearts, seven_clubs]
      end
    end

    context 'when adding a card of the wrong suit to a run' do
      it 'returns nil' do
        expect(run.try_add_cards([eight_hearts])).to be_nil
      end

      it 'does not change the meld' do
        run.try_add_cards([eight_hearts])
        expect(run.cards).to eq [five_spades, six_spades, seven_spades]
      end
    end

    context 'when adding a valid run card and a wrong card to a run' do
      it 'returns nil' do
        expect(run.try_add_cards([eight_spades, eight_hearts])).to be_nil
      end

      it 'does not change the meld' do
        run.try_add_cards([eight_spades, eight_hearts])
        expect(run.cards).to eq [five_spades, six_spades, seven_spades]
      end
    end

    context 'when adding a non-sequential card to the high end of a run' do
      it 'returns nil' do
        expect(run.try_add_cards([nine_spades])).to be_nil
      end

      it 'does not change the meld' do
        run.try_add_cards([nine_spades])
        expect(run.cards).to eq [five_spades, six_spades, seven_spades]
      end
    end

    context 'when adding a non-sequential card to the low end of a run' do
      it 'returns nil' do
        expect(run.try_add_cards([three_spades])).to be_nil
      end

      it 'does not change the meld' do
        run.try_add_cards([three_spades])
        expect(run.cards).to eq [five_spades, six_spades, seven_spades]
      end
    end
  end

  describe '#to_s' do
    it 'labels a run with its first and last card joined by a dash' do
      meld = described_class.new([
                                   Rummy::Card.new('5', 'Spades'),
                                   Rummy::Card.new('6', 'Spades'),
                                   Rummy::Card.new('7', 'Spades')
                                 ])

      expect(meld.to_s).to eq '5♠-7♠'
    end

    it 'labels a longer run with a single dash between first and last' do
      meld = described_class.new([
                                   Rummy::Card.new('5', 'Spades'),
                                   Rummy::Card.new('6', 'Spades'),
                                   Rummy::Card.new('7', 'Spades'),
                                   Rummy::Card.new('8', 'Spades')
                                 ])

      expect(meld.to_s).to eq '5♠-8♠'
    end

    it 'labels a set with the rank followed by s' do
      meld = described_class.new([
                                   Rummy::Card.new('7', 'Spades'),
                                   Rummy::Card.new('7', 'Hearts'),
                                   Rummy::Card.new('7', 'Clubs')
                                 ])

      expect(meld.to_s).to eq '7s'
    end
  end

  describe '#to_s' do
    it 'labels a run with its first and last card joined by a dash' do
      meld = described_class.new([
                                   Rummy::Card.new('5', 'Spades'),
                                   Rummy::Card.new('6', 'Spades'),
                                   Rummy::Card.new('7', 'Spades')
                                 ])

      expect(meld.to_s).to eq '5♠-7♠'
    end

    it 'labels a longer run with a single dash between first and last' do
      meld = described_class.new([
                                   Rummy::Card.new('5', 'Spades'),
                                   Rummy::Card.new('6', 'Spades'),
                                   Rummy::Card.new('7', 'Spades'),
                                   Rummy::Card.new('8', 'Spades')
                                 ])

      expect(meld.to_s).to eq '5♠-8♠'
    end

    it 'labels a set with the rank followed by s' do
      meld = described_class.new([
                                   Rummy::Card.new('7', 'Spades'),
                                   Rummy::Card.new('7', 'Hearts'),
                                   Rummy::Card.new('7', 'Clubs')
                                 ])

      expect(meld.to_s).to eq '7s'
    end
  end

  describe '#==' do
    let(:cards) do
      [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]
    end
    let(:meld) { described_class.new(cards) }

    it 'is equal when cards match' do
      other = described_class.new(cards.dup)

      expect(meld).to eq other
    end

    it 'is not equal when cards differ' do
      other = described_class.new([Rummy::Card.new('8', 'Diamonds')])

      expect(meld).to_not eq other
    end

    it 'is not equal to nil' do
      expect(meld).to_not eq nil
    end
  end

  describe '#as_json, .from_json' do
    let(:cards) do
      [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]
    end
    let(:meld) { described_class.new(cards) }

    it 'round-trips through as_json and from_json' do
      restored = described_class.from_json(meld.as_json.as_json)

      expect(restored).to eq meld
    end

    it 'restores cards as Rummy::Card instances' do
      restored = described_class.from_json(meld.as_json.as_json)

      expect(restored.cards).to all(be_a(Rummy::Card))
    end
  end
end
