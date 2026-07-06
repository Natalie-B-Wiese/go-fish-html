module GoFish
  class Player
    attr_reader :user_id

    def initialize(user_id)
      @user_id=user_id
    end

    def ==(other)
      return false if other.nil?
      
      user_id == other.user_id
    end

    def as_json(*)
      {
        user_id: user_id
      }
    end

    def self.from_json(json)
      self.new(json["user_id"])
    end

  end
end