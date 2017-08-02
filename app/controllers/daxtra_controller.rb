class DaxtraController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json, :xml

  before_action :set_key, only: [:index]
  after_filter :setup_access_control_origin

  def index
    @host = @key.host
    @app_id = params[:data][:id]
    render layout: false
  end

  # http://localhost:3001/prs/email_data.json?user[email]=bob@foo.com&user[created_at]=2014-02-11T10:01:07.000+00:00&user_profile[first_name]=Bob&user_profile[last_name]=Hoskins&job[job_title]=Testing Job&job[job_reference]=ABC123&email_name=apply_for_vacancy&target_type=job_application
  def email_data
    if params[:target_type] == 'job_application'
      @email = params[:user][:email]
      @user_profile = params[:user_profile]
      @first_name = @user_profile['first_name']
      @last_name = @user_profile['last_name']
      @registration_answer_hash = params[:registration_answer_hash] || {}
      @job = params[:job]
      body =  render_to_string(action: 'email_data.html.haml', layout: false)
      render json: { success: true, body: body }
    else
      render json: {}
    end
  end
end
