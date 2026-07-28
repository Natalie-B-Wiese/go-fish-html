module LeaderboardsHelper
  def active_sort_class(query, attribute)
    return '' unless query.sorts.first&.name == attribute.to_s

    'btn--active'
  end
end
