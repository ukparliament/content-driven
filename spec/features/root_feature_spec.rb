require 'rails_helper'

feature 'home'  do
  context 'when visiting the home pages' do
    before(:each) do
      visit root_path
    end

    scenario 'should display text home' do
      expect(page).to have_css('.breadcrumbs li a', text: 'home')
    end

    # scenario 'visit pages e' do
    #   visit root_path+'/a/b/d/e'
    #   expect(pages).to have_text 'I am a different template (number 2) and I am for "e"'
    # end

  end
end