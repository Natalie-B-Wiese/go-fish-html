require 'rails_helper'
RSpec.describe 'Pages', type: :system do
  context 'pages/rules' do
    it 'shows the rules index' do
      visit '/pages/rules'
      expect(page).to have_content 'Rules'
    end
  end
  
end