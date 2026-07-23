class RummyGamePresenter < GamePresenter
  def can_draw?
    my_turn? && !implementation.has_drawn
  end

  def discard_card
    implementation.discard_pile.top_card
  end

  def can_take_discard?
    can_draw? && !implementation.discard_pile.empty?
  end
end
