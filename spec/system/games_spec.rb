require 'rails_helper'
RSpec.describe 'Games', type: :system do
  context '/games' do
    it 'shows the games index' do
      visit '/games'
      expect(page).to have_content 'Your Games'
      expect(page).to have_content 'All Games'
    end
  end

  context '/games/history' do
    it 'shows the history' do
      visit '/games/history'
      expect(page).to have_content 'History'
    end
  end
  
end