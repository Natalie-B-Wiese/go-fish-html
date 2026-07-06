class GoFish

  def initialize(players)
  end

  def as_json(*)
    # {
    # players: players.map(&:as_json),
    # current_player_index: @index,
    # deck: deck.as_json
    # }
  end

  def self.load(json)
    # return nil if json.blank?
    # from_json(json)
  end

  def self.dump(obj)
    # obj.as_json
  end

end