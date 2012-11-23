class Admin::AdminUsersController < Admin::BaseController
  def index
    @admin_users = AdminUser.all
  end
end
