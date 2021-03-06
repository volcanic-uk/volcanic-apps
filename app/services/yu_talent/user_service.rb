require 'uri'
require 'open-uri'
require 'base64'
require 'oauth2'

class YuTalent::UserService < BaseService

  API_ENDPOINT = "https://www.yutalent.co.uk/c/oauth/v1?method="

  def initialize(user)
    @user         = user
    if @user.user_data['user_group_name'].present?
      @user_group_name    = @user.user_data['user_group_name']
    else
      @user_group_name    = @user.user_data['user_type']
    end
    @dataset_id   = @user.user_data['dataset_id']
    @access_token = set_access_token
  end


  def save_user
    begin
      # @yutalent_id = check_duplicates
      # return if @yutalent_id.present?
      # map contact attributes
      @new_cv = true
      @new_avatar = true
      @contact_attributes               = map_contact_attributes
      @contact_attributes[:project_id]  = project_id
      @contact_attributes[:status_id]   = status_id('new')
      @contact_attributes[:type]        = type_id(@user_group_name)
      # post contact attributes
      # Rails.logger.info "--- @contact_attributes 4: #{@contact_attributes}"
      @response = @access_token.post(URI.decode(API_ENDPOINT + "contacts/add"), body: @contact_attributes)
      @response_body = JSON.parse(@response.body)
      # Rails.logger.info "--- @response_body: #{@response_body}"
      # update user details
      if @response_body['id'].present?
        @user.update(
          yu_talent_uid: @response_body['id'],
          project_id:    @contact_attributes[:project_id],
          status_id:     @contact_attributes[:status_id],
          type_id:       @contact_attributes[:type]
        )
      end
    rescue => e
      Rails.logger.info "--- yu:talent save_user exception ----- : #{e.message}"
    end
  end

  def update_user(new_cv, new_avatar)
    @new_cv = new_cv
    @new_avatar = new_avatar
    begin
      # map contact attributes
      # Rails.logger.info "--- ABOUT TO map_contact_attributes"
      @contact_attributes               = map_contact_attributes
      @contact_attributes[:contact_id]  = @user.yu_talent_uid
      @contact_attributes[:project_id]  = project_id
      @contact_attributes[:status_id]   = status_id('new')
      @contact_attributes[:type]        = type_id(@user_group_name)
      # Rails.logger.info "--- @contact_attributes = #{@contact_attributes.inspect}"
      # post contact attributes
      @response = @access_token.post(URI.decode(API_ENDPOINT + "contacts/edit"), body: @contact_attributes)
      @response_body = JSON.parse(@response.body)
      # Rails.logger.info "--- @response_body = #{@response_body.inspect}"
      # update user details
    rescue => e
      Rails.logger.info "--- yu:talent update_user exception ----- : #{e.message}"
    end
  end

  def check_duplicates
    Rails.logger.info "--- STARTING check_duplicates"
    begin
      if @user.yu_talent_uid.present?
        yutalent_id = @user.yu_talent_uid
      else
        @dup_attributes = Hash.new
        @dup_attributes[:email] = @user.email
        # Rails.logger.info "--- @dup_attributes: #{@dup_attributes.inspect}"
        @response = @access_token.post(URI.decode(API_ENDPOINT + "contacts/check-duplicates"), body: @dup_attributes)
        # Rails.logger.info "--- @response: #{@response.inspect}"
        @duplicate_contacts = JSON.parse(@response.body)
        # Rails.logger.info "--- @duplicate_contacts: #{@duplicate_contacts.inspect}"
        if @duplicate_contacts.count > 0
          # Rails.logger.info '--- yu:talent DUPLICATE CANDIDATE RECORD FOUND'
          @response_body  = JSON.parse(@response.body)
          @last_candidate = @response_body.last
          # Rails.logger.info "--- @last_candidate: #{@last_candidate.inspect}"
          yutalent_id     = @last_candidate.id
        else
          yutalent_id = nil
        end
      end
      return yutalent_id
    rescue => e
      Rails.logger.info "--- yu:talent check_duplicates exception ----- : #{e.message}"
    end
  end


  private

    def set_access_token
      @client             = YuTalent::AuthenticationService.client
      @settings           = YuTalentAppSetting.find_by(dataset_id: @dataset_id)
      @access_token_hash  = JSON.parse(@settings.try(:access_token))
      @access_token       = OAuth2::AccessToken.from_hash(@client, @access_token_hash)
      return @access_token
    end


    def status_id(status = 'new')
      @response       = @access_token.get(URI.decode(API_ENDPOINT + 'statuses/list'))
      @response_body  = JSON.parse(@response.body)
      @status_id      = "default_1" #defaults to new
      @response_body.map do |s|
        @status_id    = s['id'] if s['status'].try(:downcase) == status.try(:downcase)
      end
      return @status_id
    end


    def type_id(type = 'candidate')
      # maps to yu:talent category_id
      @response       = @access_token.get(URI.decode(API_ENDPOINT + 'contacts/categories'))
      @response_body  = JSON.parse(@response.body)
      @type_id        = nil
      @response_body.map do |t|
        @type_id      = t['id'] if t['name'].try(:downcase) == type.try(:downcase)
      end
      return @type_id
    end


    def project_id
      @response       = @access_token.get(URI.decode(API_ENDPOINT + 'projects/list'))
      @response_body  = JSON.parse(@response.body)
      @project        = @response_body.last
      return @project['id']
    end


    def map_contact_attributes
      # Rails.logger.info "--- STARTING map_contact_attributes"
      @attributes                       = Hash.new
      @attributes[:data]                = Hash.new
      @attributes[:data][:name]         = candidate_name
      @attributes[:data][:email]        = @user.email
      if @settings.background_info.present?
        bg_info = @user.registration_answers[@settings.background_info] rescue nil
      elsif @user.linkedin_profile.present?
        bg_info = linkedin_background_info
      else
        bg_info = nil
      end
      @attributes[:data][:background_info] = bg_info
      # @attributes[:data][:company_website] =
      @attributes[:data][:company_name] = @user.registration_answers[@settings.company_name] if @settings.company_name.present? && @user.registration_answers[@settings.company_name].present?
      @attributes[:data][:location]     = @user.registration_answers[@settings.location] if @settings.location.present? && @user.registration_answers[@settings.location].present?
      @attributes[:data][:history]      = linkedin_work_history if @user.linkedin_profile.present?
      # @attributes[:data][:education]    = linkedin_education_history if @user.linkedin_profile.present?
      @attributes[:data][:facebook]     = @user.user_profile['facebook_url'] if @user.user_profile['facebook_url'].present?
      @attributes[:data][:linkedin]     = @user.user_profile['li_publicProfileUrl'] if @user.user_profile['li_publicProfileUrl'].present?
      @attributes[:data][:phone]        = @user.registration_answers[@settings.phone] if @settings.phone.present? && @user.registration_answers[@settings.phone].present?
      @attributes[:data][:phone_mobile] = @user.registration_answers[@settings.phone_mobile] if @settings.phone_mobile.present? && @user.registration_answers[@settings.phone_mobile].present?
      @attributes[:data][:position]     = @user.registration_answers[@settings.position] if @settings.position.present? && @user.registration_answers[@settings.position].present?
      # Rails.logger.info "--- @attributes = #{@attributes.inspect}"
      # Rails.logger.info "--- CONSIDERING THE CREATION OF CV DATA. @new_cv: #{@new_cv}"
      if @new_cv && @user.user_profile['upload_path'].present? && @user.user_profile['upload_name'].present?
        # Rails.logger.info "--- CONDITIONS MET TO CREATE CV DATA"
        @attributes[:data][:cv]           = Hash.new
        @attributes[:data][:cv][:content] = base64_encoder(@user.user_profile['upload_path'])
        @attributes[:data][:cv][:name]    = @user.user_profile['upload_name']
        # Rails.logger.info "--- CREATED CV DATA"
      end
      @attributes[:data][:avatar]       = base64_encoder(@user.user_profile['li_pictureUrl']) if @new_avatar && @user.user_profile['li_pictureUrl'].present?
      # Rails.logger.info "--- FINISHED map_contact_attributes: #{@attributes.inspect}"
      return @attributes
    end


    def candidate_name
      # format candidate name
      @first_name = @user.user_profile['first_name']
      @last_name  = @user.user_profile['last_name']
      if @first_name.present? && @last_name.present?
        "#{@first_name} #{@last_name}"
      else
        "#{@first_name}" || "#{@last_name}"
      end
    end


    def base64_encoder(path)
      require 'uri'
      require 'open-uri'
      require 'base64'
      # Rails.logger.info "--- STARTING BASE64 ENCODING OF CV"
      # @host             = Key.find_by(app_dataset_id: @dataset_id).try(:host)
      if Rails.env.development? && path.start_with?("/s3/")
        # @url              = URI.decode('http://' + @host + path)
        @url = URI.decode('https://dti2gc0g5oj0i.cloudfront.net' + path)
      else
        @url            = URI.decode(path)
      end
      # Rails.logger.info "--- OPENING CV URL: #{@url}"
      @resource         = open(@url).read
      # Rails.logger.info "--- ABOUT TO BASE64 ENCODE OPENED CV FILE"
      @encoded_resource = Base64.encode64(@resource)
      # Rails.logger.info "--- FINISHED BASE64 ENCODING OF OPENED CV FILE"
      return @encoded_resource
    end


    def linkedin_background_info
      # linkedin_education_history
      # linkedin_skills
      linkedin_work_history
    end


    def linkedin_work_history
      # Rails.logger.info "--- STARTING linkedin_work_history"
      unless !@user.linkedin_profile['positions'].present?
        # Rails.logger.info "--- POSITIONS #{@user.linkedin_profile['positions'].inspect}"
        if @user.linkedin_profile['positions'].size > 0
          string              = '<h3>PREVIOUS EXPERIENCE</h3>'
          @user.linkedin_profile['positions'].each do |position|
            # Rails.logger.info "--- POSITION: #{position.inspect}"
            string            = string + '<p>'
            company_name      = position['company_name'].present? ? 'Company: ' + position['company_name'] + '<br />' : "Company: N/A<br />"
            title             = position['title'].present? ? 'Position: ' + position['title'] + '<br />' : "Position: N/A<br />"
            start_date        = position['start_date'].present? ? 'Start Date: ' + position['start_date'] + '<br />' : "Start Date: N/A<br />"
            end_date          = position['end_date'].present? ? 'End Date: ' + position['end_date'] + '<br />' : "End Date: N/A<br />"
            summary           = position['summary'].present? ? 'Summary: ' + position['summary'] + '<br />' : "Summary: N/A<br />"
            company_industry  = position['company_industry'].present? ? 'Company Industry: ' + position['company_industry'] + '<br />' : "Company Industry: N/A<br />"
            string            = string + company_name + title + start_date + end_date + summary + company_industry + '</p>'
            # Rails.logger.info "--- string: #{string}"
          end
          return string
        end
      end
    end


    # def linkedin_education_history
    #   unless !@user.linkedin_profile['education_history'].present?
    #     if @user.linkedin_profile['education_history'].size > 0
    #       string            = string + '<h3>EDUCATION</h3>'
    #       @user.linkedin_profile['education_history'].each do |education|
    #         string          = string + '<p>'
    #         string          = string + education['school_name'] + '<br />' unless education['school_name'].blank?
    #         field_of_study  = education['field_of_study'].present? ? 'Field of Study: ' + education['field_of_study'] + '<br />' : "Field of Study: N/A<br />"
    #         start_date      = education['start_date'].present? ? 'Start Date: ' + education['start_date'] + '<br />' : "Start Date: N/A<br />"
    #         end_date        = education['end_date'].present? ? 'End Date: ' + education['end_date'] + '<br />' : "End Date: N/A<br />"
    #         degree          = education['degree'].present? ? 'Degree: ' + education['degree'] + '<br />' : "Degree: N/A<br />"
    #         activities      = education['activities'].present? ? 'Activities: ' + education['activities'] + '<br />' : "Activities: N/A<br />"
    #         notes           = education['notes'].present? ? 'Notes: ' + education['notes'] + '<br />' : "Notes: N/A<br />"
    #         string          = string + field_of_study + start_date + end_date + degree + activities + notes + '</p>'
    #       end
    #       return string
    #     end
    #   end
    # end


    # def linkedin_skills
    #   unless !@user.linkedin_profile['skills'].present?
    #     if @user.linkedin_profile['skills'].size > 0
    #       string        = string + '<h3>SKILLS</h3>'
    #       @user.linkedin_profile['skills'].each do |skill|
    #         string      = string + '<p>'
    #         skill_name  = skill['skill'].present? ? 'Skill: ' + skill['skill'] + '<br />' : "Skill: N/A<br />"
    #         proficiency = skill['proficiency'].present? ? 'Proficiency: ' + skill['proficiency'] + '<br />' : "Proficiency: N/A<br />"
    #         years       = skill['years'].present? ? 'Years: ' + skill['years'] + '<br />' : "Years: N/A<br />"
    #         string      = string + skill_name + proficiency + years + '</p>'
    #       end
    #       return string
    #     end
    #   end
    # end

end
