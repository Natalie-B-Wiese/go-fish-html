module GoFish
  class Game
    attr_reader :players

    def initialize(players)
      @players=players
    end

    def deal!
      # TODO: make it deal the cards
    end

    def as_json(*)
      {
        players: players.map(&:as_json)
      }
      # {
      # players: players.map(&:as_json),
      # current_player_index: @index,
      # deck: deck.as_json
      # }
    end

    def ==(other)
      return false if other.nil?
      
      players==other.players
    end

    def self.from_json(json)
      # makes it not care whether json uses string or keys to index
      json=json.with_indifferent_access

      self.new(json["players"].map { |player_json| GoFish::Player.from_json(player_json) })
    end

    def self.load(json)
      return nil if json.blank?
      from_json(json)
    end

    def self.dump(obj)
      obj.as_json
    end 

  end
end