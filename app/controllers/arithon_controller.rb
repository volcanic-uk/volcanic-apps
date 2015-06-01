class ArithonController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin
  # before_action :set_key, only: [:index, :job_application]

  def index
    @settings = ArithonSetting.find_by(dataset_id: params[:data][:dataset_id])
    @settings = ArithonSetting.new unless @settings.present?
  end

  def save_user
    @user = ArithonUser.find_by(user_id: params[:user][:id])
    if @user.present?
      if @user.update(
        email: params[:user][:email],
        user_data: params[:user],
        user_profile: params[:user_profile],
        linkedin_profile: params[:linkedin_profile],
        registration_answers: params[:registration_answer_hash]
      )
        logger.info "--- params = #{params.inspect}"
        post_user_to_arithon(@user, params)
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    else
      @user = ArithonUser.new
      @user.user_id = params[:user][:id]
      @user.email = params[:user][:email]
      @user.user_data = params[:user]
      @user.user_profile = params[:user_profile]
      @user.linkedin_profile = params[:linkedin_profile]
      @user.registration_answers = params[:registration_answer_hash]

      if @user.save
        post_user_to_arithon(@user, params)
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    end
  end

  def upload_cv
    @user = ArithonUser.find_by(user_id: params[:user][:id])
    if @user.update(
      email: params[:user][:email],
      user_data: params[:user],
      user_profile: params[:user_profile]
    )
      # logger.info "--- params = #{params.inspect}"
      render json: { success: true, user_id: @user.id }
    else
      render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
    end
  end

  def save_settings
    @settings = ArithonSetting.find_by(dataset_id: params[:arithon_setting][:dataset_id])
    if @settings.present?
      if @settings.update(params[:arithon_setting].permit!)
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end
    else
      @settings = ArithonSetting.new(params[:arithon_setting].permit!)
      if @settings.save
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end
    end
  end

  private

  def post_user_to_arithon(user, params)

  end
end
