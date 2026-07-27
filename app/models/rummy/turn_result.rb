module Rummy
  class TurnResult
    TAKE_DECK = 'drew a'.freeze
    TAKE_DISCARD = 'took the'.freeze
    MELD = 'melded'.freeze
    LAY_OFF = 'laid off'.freeze
    DISCARD = 'discarded'.freeze

    attr_reader :current_user_id
    attr_accessor :card_received_deck, :card_received_discard, :card_discarded, :meld, :laid_off_cards

    def initialize(current_user_id:, card_received_deck: nil, card_received_discard: nil, card_discarded: nil,
                   meld: nil, laid_off_cards: [])
      @current_user_id = current_user_id
      @card_received_deck = card_received_deck
      @card_received_discard = card_received_discard
      @card_discarded = card_discarded
      @meld = meld
      @laid_off_cards = laid_off_cards
    end

    def card_received
      card_received_deck || card_received_discard
    end

    def request_message(user_names_by_id)
      return deck_draw_message(user_names_by_id) if card_received_deck
      return discard_draw_message(user_names_by_id) if card_received_discard
      return lay_off_message(user_names_by_id) if meld && !laid_off_cards.empty?
      return meld_message(user_names_by_id) if meld

      discard_message(user_names_by_id) if card_discarded
    end

    def action_message(_user_names_by_id)
      ''
    end

    def result_message(_user_names_by_id)
      ''
    end

    def as_json
      {
        'current_user_id' => current_user_id,
        'card_received_deck' => card_received_deck.as_json,
        'card_received_discard' => card_received_discard.as_json,
        'card_discarded' => card_discarded.as_json,
        'meld' => meld&.as_json,
        'laid_off_cards' => laid_off_cards.map(&:as_json)
      }
    end

    def self.from_json(json)
      new(
        current_user_id: json['current_user_id'],
        card_received_deck: card_from_json(json['card_received_deck']),
        card_received_discard: card_from_json(json['card_received_discard']),
        card_discarded: card_from_json(json['card_discarded']),
        meld: meld_from_json(json['meld']),
        laid_off_cards: (json['laid_off_cards'] || []).map { |card_json| Card.from_json(card_json) }
      )
    end

    def self.card_from_json(card_json)
      card_json.nil? ? nil : Card.from_json(card_json)
    end

    def self.meld_from_json(meld_json)
      meld_json.nil? ? nil : Meld.from_json(meld_json)
    end

    def ==(other)
      return false if other.nil?

      current_user_id == other.current_user_id &&
        card_received_deck == other.card_received_deck &&
        card_received_discard == other.card_received_discard &&
        card_discarded == other.card_discarded &&
        meld == other.meld &&
        laid_off_cards == other.laid_off_cards
    end

    private

    def current_user_name(user_names_by_id)
      user_names_by_id.fetch(current_user_id)
    end

    def deck_draw_message(user_names_by_id)
      "#{current_user_name(user_names_by_id)} #{TAKE_DECK} card from the deck."
    end

    def discard_draw_message(user_names_by_id)
      "#{current_user_name(user_names_by_id)} #{TAKE_DISCARD} #{card_received_discard} from the discard pile."
    end

    def meld_message(user_names_by_id)
      "#{current_user_name(user_names_by_id)} #{MELD} #{meld.cards.join(', ')}."
    end

    def lay_off_message(user_names_by_id)
      "#{current_user_name(user_names_by_id)} #{LAY_OFF} #{laid_off_cards.join(', ')}."
    end

    def discard_message(user_names_by_id)
      "#{current_user_name(user_names_by_id)} #{DISCARD} #{card_discarded}."
    end
  end
end
