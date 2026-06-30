require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let(:user) {create(:user)}
  
  before do
    log_user_in(user)
  end

  context '/games' do
    it 'shows the games index' do
      visit games_path
      expect(page).to have_content 'Your Games'
      expect(page).to have_content 'All Games'
    end
  end

  context '/games/history' do
    it 'shows the history' do
      visit games_history_path
      expect(page).to have_content 'History'
    end
  end
end