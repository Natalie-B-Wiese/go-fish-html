class Implementation
  attr_reader :players, :deck, :feed
  attr_accessor :current_player_index

  def initialize(players, deck: Deck.new, current_player_index: 0, feed: [])
    @players = players
    @deck = deck
    @feed = feed
    @current_player_index = current_player_index
  end

  def start!
    raise NotImplementedError, "#{self.class} must implement #start!"
  end

  def game_over?
    raise NotImplementedError, "#{self.class} must implement #game_over?"
  end

  def winning_player
    raise NotImplementedError, "#{self.class} must implement #winning_player"
  end

  def self.player_class
    raise NotImplementedError, "#{self.class} must implement .player_class"
  end

  def self.turn_result_class
    raise NotImplementedError, "#{self.class} must implement .turn_result_class"
  end

  def self.deck_class
    Deck
  end

  def ==(other)
    return false if other.nil?

    players == other.players &&
      deck == other.deck &&
      current_player_index == other.current_player_index &&
      feed == other.feed
  end

  def self.load(json)
    return nil if json.blank?

    from_json(json)
  end

  def self.dump(obj)
    obj.as_json
  end

  # keys are the user id and values are the specific Implementation Players
  def players_hash
    players.index_by(&:user_id)
  end

  def as_json
    {
      players: players.map(&:as_json),
      deck: deck.as_json,
      current_player_index: current_player_index,
      feed: feed.map(&:as_json)
    }
  end

  def self.json_attributes(json)
    {
      deck: deck_class.from_json(json['deck']),
      current_player_index: json['current_player_index'],
      feed: json['feed'].map { |turn_result_json| turn_result_class.from_json(turn_result_json) }
    }
  end

  def self.from_json(json)
    players = json['players'].map { |player_json| player_class.from_json(player_json) }
    new(players, **json_attributes(json))
  end

  def switch_turn
    self.current_player_index += 1
    self.current_player_index = 0 if current_player_index >= players.length
  end

  def current_user_id
    players[current_player_index].user_id
  end

  # the Implementation player whose turn it is
  def current_player
    players[current_player_index]
  end

  private

  def starting_hand_size
    raise NotImplementedError, "#{self.class} must implement private method #starting_hand_size"
  end

  # NOTE: this method is called by the child classes
  def deal_deck_cards_to_players(num_cards_to_deal)
    num_cards_to_deal.times do
      players.each do |player|
        player.add_card(deck.shift_card)
      end
    end
  end

  def deal
    deck.shuffle
    deal_deck_cards_to_players(starting_hand_size)
  end
end
