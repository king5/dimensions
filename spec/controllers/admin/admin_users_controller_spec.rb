require 'spec_helper'

describe Admin::AdminUsersController do
  login_admin

  context '#index' do
    it 'Should display a list of admin users' do
      visit admin_admin_users_path
      page.should have_content "admin@example.com"
    end
  end
end
