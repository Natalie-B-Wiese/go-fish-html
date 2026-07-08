require 'rails_helper'
RSpec.describe 'Pages', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in_as(user)
  end

  context 'pages/rules' do
    it 'shows the rules index' do
      visit pages_rules_path
      expect(page).to have_content 'Rules'
    end
  end
end
