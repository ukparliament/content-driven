require 'rails_helper'

feature 'home'  do
  context 'when visiting the home page' do
    before(:each) do
      visit root_path
    end

    scenario 'should display text home' do
      expect(page).to have_text 'home'
    end

  end
end