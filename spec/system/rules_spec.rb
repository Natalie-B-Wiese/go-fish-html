require 'rails_helper'
RSpec.describe 'Pages', type: :system do
  it 'shows the rules index' do
    visit '/pages'
    expect(page).to have_content 'Rules'
  end
end