class BondAdaptController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]

  def index
    @host = @key.host
    @app_id = params[:data][:id]
    @bond_adapt_setting = BondAdaptAppSetting.find_by(dataset_id: params[:data][:dataset_id]) || BondAdaptAppSetting.new(dataset_id: params[:data][:dataset_id])
    render layout: false
  end

  def save_settings
    @key = Key.find_by(app_dataset_id: params[:bond_adapt_app_setting][:dataset_id], app_name: params[:controller])
    @bond_adapt_setting = BondAdaptAppSetting.find_by(dataset_id: params[:bond_adapt_app_setting][:dataset_id])

    if @bond_adapt_setting.present?
      if @bond_adapt_setting.update(params[:bond_adapt_app_setting].permit!)
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end
    else
      @bond_adapt_setting = BondAdaptAppSetting.new(params[:bond_adapt_app_setting].permit!)
      if @bond_adapt_setting.save
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end
    end
  end
  
  def save_user
    # Only send certain emails while testing
    if set_user_email.ends_with?('@volcanic.co.uk') || set_user_email.ends_with?('@ojassociates.com')
      BondAdapt::UserService.new({dataset_id: params["dataset_id"], 
        user_name: set_user_name, 
        user_email: set_user_email, 
        user_phone: req_quest_finder("mobile-number"), 
        user_url: set_user_linkedin, 
        user_location: req_quest_finder("preferred-location"), 
        user_sector: req_quest_finder("preferred-sector"), 
        user_permanent: set_contract_type("Permanent"),
        user_contract: set_contract_type("Contract")}).send_to_bond_adapt(choose_reg_type.to_s)
    end
  end
  
  private
     
    def choose_reg_type
      if user_reg_qus.present? && any_full_reg_feilds?
        'create_user_full_reg'
      else
        'create_user'
      end
    end
    
    def any_full_reg_feilds?
      cortact_array.present? || user_reg_qus["preferred-sector"].present? || user_reg_qus["preferred-location"].present? 
    end
    
    def req_quest_finder(question)
      if user_reg_qus.present?
        user_reg_qus[question.to_s]
      else
        ""
      end 
    end
    
    def set_contract_type(contract_type)
      if user_reg_qus.present? && cortact_array.present?
        cortact_array.include?(contract_type.to_s).to_s 
      else
        "false"
      end
    end
    
    def cortact_array
      if user_reg_qus.present?
        @cortact_array_var ||= user_reg_qus["perm-slash-contract_array"]
      end
    end
    
    def set_user_name
      if user_profile_params.present?
        @user_name_var ||= user_profile_params['first_name'].to_s << " " << user_profile_params['last_name'].to_s
      else
        ""
      end
    end
    
    def set_user_email
      if user_params.present?
        @user_email_var ||= user_params["email"]
      else
        ""
      end
    end
    
    def set_user_linkedin
      if user_profile_params.present?
        @set_user_linkedin_var ||= user_profile_params["li_publicProfileUrl"]
      else
        ""
      end
    end
    
    def user_params
      @user_params_var ||= params["user"]
    end
    
    def user_profile_params
      @user_profile_params_var ||= params["user_profile"]
    end
    
    def user_reg_qus
      @user_reg_qus_var ||= params["registration_answer_hash"]
    end
end