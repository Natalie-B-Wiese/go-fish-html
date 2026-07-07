module GoFish
  class Game
    SMALL_GAME_CARDS = 7
    BIG_GAME_CARDS = 5

    attr_reader :players, :deck, :current_player_index

    def initialize(players, deck: Deck.new, current_player_index: 0)
      @players=players
      @deck = deck
      @current_player_index=current_player_index
    end

    def deal!
      deck.shuffle
      if players.length <= 3
        deal_cards_to_players(SMALL_GAME_CARDS)
      else
        deal_cards_to_players(BIG_GAME_CARDS)
      end
    end

    def as_json
      {
        players: players.map(&:as_json),
        deck: deck.as_json,
        current_player_index: current_player_index
      }
    end

    def ==(other)
      return false if other.nil?
      as_json==other.as_json
    end

    def self.from_json(json)      
      json_players=json["players"].map { |player_json| GoFish::Player.from_json(player_json) }
      json_deck=Deck.from_json(json["deck"])

      self.new(json_players, deck: json_deck, current_player_index: json["current_player_index"])
    end

    def self.load(json)
      return nil if json.blank?
      from_json(json)
    end

    def self.dump(obj)
      obj.as_json
    end 

    private

    def deal_cards_to_players(num_cards_to_deal)
      num_cards_to_deal.times do
        players.each do |player|
          player.add_card(deck.take_top_card)
        end
      end
    end

  end
end