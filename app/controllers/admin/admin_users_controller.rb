class Admin::AdminUsersController < Admin::BaseController
  def index
    @admin_users = AdminUser.all
  end

  def new
    @admin_user = AdminUser.new
  end

  def create
    @admin_user = AdminUser.new(params[:admin_user])
    if @admin_user.save
      flash[:notice]="Successfully created admin user"
      redirect_to admin_admin_users_path
    else
      flash[:alert]="Could not create new user"
      redirect_to new_admin_admin_users_path
    end
  end

  def destroy
    begin
      if AdminUser.destroy(params[:id])
        flash[:notice]="Successfully deleted user #{params[:id]}"
        redirect_to admin_admin_users_path
      else
        flash[:alert]="Something went wrong"
        redirect_to admin_admin_users_path
      end
    rescue Exception => e
      flash[:alert]="Something went wrong #{e.to_s}"
    end
  end
end
