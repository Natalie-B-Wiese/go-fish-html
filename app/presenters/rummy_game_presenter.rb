class RummyGamePresenter < GamePresenter
  def can_draw?
    my_turn? && !implementation.has_drawn
  end
end
