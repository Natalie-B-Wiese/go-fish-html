module Rummy
  class Card < ::Card
    def value
      return 1 if rank == 'A'

      super
    end
  end
end
