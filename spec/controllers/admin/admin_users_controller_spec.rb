require 'spec_helper'

describe Admin::AdminUsersController do
  context '#index' do
    it 'Should display a list of admin users' do
      get :index
    end
  end
end
