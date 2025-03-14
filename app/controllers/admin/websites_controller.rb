class Admin::WebsitesController < AdminController
  before_action :set_website, only: [
    :show, :costs, :statuscard, :edit, :update, :destroy, :collection_request,
    :approve,
    :deny,
    :events
  ]

  def index
    if params[:all]
      @websites = Website.all.order(:production_status, :domain)
    else
      @websites = Website.active.order(:production_status, :domain)
    end
  end

  def export_csv
    @websites = Website.all
    send_data @websites.to_csv
  end

  def statuscard
  end

  def search
    search_text = params[:search]
    if search_text.present?
      search_text = "%" + search_text + "%"
      @websites = Website.where(" domain ilike ? or office ilike ? or sub_office ilike ? or production_status ilike ? or site_owner_email ilike ? ", search_text, search_text, search_text, search_text, search_text)
    else
      @websites = Website.all
    end
  end

  def gsa
    @websites = Website.all
  end

  def show
  end

  def collection_preview
    ensure_admin
    @websites = Website.active.order(:site_owner_email, :domain)
  end

  def collection_request
    # fetch all websites for site owner
    @websites = Website.active.where(site_owner_email: @website.site_owner_email)
    # only include websites which are missing data
    @websites = @websites.select { | ws | ws.requiresDataCollection? }
    UserMailer.website_data_collection(@website.site_owner_email, @websites).deliver_later if @website.site_owner_email.present?
    UserMailer.website_data_collection(current_user.email, @websites).deliver_later
    redirect_to admin_websites_url, notice: "Website data collection request was successfully sent for #{@website.domain}"
  end

  def new
    @website = Website.new
  end

  def edit
    ensure_website_admin(website: @website, user: current_user)
  end

  def costs
    ensure_website_admin(website: @website, user: current_user)
  end

  def create
    @website = Website.new(admin_website_params)

    if @website.save
      Event.log_event(Event.names[:website_created], "Website", @website.id, "Website #{@website.domain} created at #{DateTime.now}", current_user.id)
      UserMailer.website_created(website: @website).deliver_later
      redirect_to admin_website_url(@website), notice: 'Website was successfully created.'
    else
      render :new
    end
  end

  def update
    ensure_website_admin(website: @website, user: current_user)
    current_state = @website.production_status
    if @website.update(admin_website_params)
      log_update(current_state)
      redirect_to admin_website_url(@website), notice: 'Website was successfully updated.'
    else
      render :edit
    end
  end

  def approve
    ensure_website_admin(website: @website, user: current_user)
    @website.approve
    if @website.save
      Event.log_event(Event.names[:website_approved], "Website", @website.id, "Website #{@website.domain} approved at #{DateTime.now}", current_user.id)
      redirect_to admin_website_url(@website), notice: "Website #{@website.domain} was approved."
    else
      render :edit
    end
  end

  def deny
    ensure_website_admin(website: @website, user: current_user)
    @website.deny
    if @website.save
      Event.log_event(Event.names[:website_denied], "Website", @website.id, "Website #{@website.domain} denied at #{DateTime.now}", current_user.id)
      redirect_to admin_website_url(@website), notice: "Website #{@website.domain} was denied."
    else
      render :edit
    end
  end

  def destroy
    ensure_admin

    @website.destroy
    Event.log_event(Event.names[:website_deleted], "Website", @website.id, "Website #{@website.domain} deleted at #{DateTime.now}", current_user.id)
    redirect_to admin_websites_url, notice: 'Website was successfully destroyed.'
  end

  def events
    @events = Event.where(object_type: "Website", object_id: @website.id).order(:created_at)
  end

  private

    def log_update(current_state)
      Event.log_event(Event.names[:website_updated], "Website", @website.id, "Website #{@website.domain} updated at #{DateTime.now}", current_user.id)
      if admin_website_params[:production_status] != current_state
        Event.log_event(Event.names[:website_state_changed], "Website", @website.id, "Website #{@website.domain} state changed to #{admin_website_params[:production_status]} at #{DateTime.now}", current_user.id)
      end
    end

    def set_website
      @website = Website.find_by_id(params[:id])
    end

    def admin_website_params
      params.require(:website).permit(:domain, :parent_domain, :office, :office_id, :sub_office, :suboffice_id, :contact_email, :site_owner_email, :production_status, :type_of_site, :digital_brand_category, :redirects_to, :status_code, :cms_platform, :required_by_law_or_policy, :has_dap, :dap_gtm_code, :cost_estimator_url, :modernization_plan_url, :annual_baseline_cost,
      :modernization_cost,
      :modernization_cost_2021,
      :modernization_cost_2022,
      :modernization_cost_2023,
      :analytics_url,
      :current_uswds_score,
      :uswds_version,
      :uses_feedback, :feedback_tool, :sitemap_url, :mobile_friendly, :has_search, :uses_tracking_cookies,
      :hosting_platform,
      :has_authenticated_experience,
      :authentication_tool,
      :repository_url,
      :notes)
    end
end
