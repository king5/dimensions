require 'spec_helper'

describe Admin::AdminUsersController do
  login_admin

  context '#index' do
    it 'should be 200' do
      get :index
    end
  end
end
