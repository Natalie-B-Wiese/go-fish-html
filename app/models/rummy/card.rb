module Rummy
  class Card < ::Card
    def value
      return 0 if rank == 'A'

      super + 1
    end
  end
end
