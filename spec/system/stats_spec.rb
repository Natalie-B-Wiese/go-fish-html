require 'rails_helper'
RSpec.describe 'Stats', type: :system do
  context 'stats' do
    it 'shows the stats index' do
      visit stats_path
      expect(page).to have_content 'Stats'
    end
  end
end