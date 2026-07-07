module GoFish
  class Game
    SMALL_GAME_CARDS = 7
    BIG_GAME_CARDS = 5

    attr_reader :players, :deck, :feed

    attr_accessor :current_player_index

    def initialize(players, deck: Deck.new, current_player_index: 0, feed: [])
      @players=players
      @deck = deck
      @feed=feed
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
        current_player_index: current_player_index,
        feed: feed.map(&:as_json)
      }
    end

    def ==(other)
      return false if other.nil?

      (players==other.players &&
      deck==other.deck &&
      current_player_index==other.current_player_index &&
      feed==other.feed)
    end

    def self.from_json(json)      
      json_players=json["players"].map { |player_json| GoFish::Player.from_json(player_json) }
      json_deck=Deck.from_json(json["deck"])
      json_feed=json["feed"].map {|turn_result_json| GoFish::TurnResult.from_json(turn_result_json)}

      self.new(json_players, deck: json_deck, current_player_index: json["current_player_index"], feed: json_feed)
    end

    def self.load(json)
      return nil if json.blank?
      from_json(json)
    end

    def self.dump(obj)
      obj.as_json
    end 

    def play_turn(current_user_id:, opponent_user_id:, rank_requested: )
      feed.push(TurnResult.new(current_user_id: Current.user.id, opponent_user_id: opponent_user_id, rank_requested: rank_requested))
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