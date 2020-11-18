# frozen_string_literal: true

module UsersHelper
  def user_link(user)
    link_to(user.name, user_path(user),
            title: user.email,
            class: 'has-tooltip commit-committer-link')
  end

  def user_email_help_text(user)
    return 'We also use email for avatar detection if no avatar is uploaded' unless user.unconfirmed_email.present?

    confirmation_link = link_to 'Resend confirmation e-mail', user_confirmation_path(user: { email: @user.unconfirmed_email }), method: :post

    h('Please click the link in the confirmation email before continuing. It was sent to ') +
      content_tag(:strong) { user.unconfirmed_email } + h('.') +
      content_tag(:p) { confirmation_link }
  end

  def profile_tabs
    @profile_tabs ||= get_profile_tabs
  end

  def profile_tab?(tab)
    profile_tabs.include?(tab)
  end

  def user_internal_regex_data
    settings = Gitlab::CurrentSettings.current_application_settings

    pattern, options = if settings.user_default_internal_regex_enabled?
                         regex = settings.user_default_internal_regex_instance
                         JsRegex.new(regex).to_h.slice(:source, :options).values
                       end

    { user_internal_regex_pattern: pattern, user_internal_regex_options: options }
  end

  def current_user_menu_items
    @current_user_menu_items ||= get_current_user_menu_items
  end

  def current_user_menu?(item)
    current_user_menu_items.include?(item)
  end

  # Used to preload when you are rendering many projects and checking access
  #
  # rubocop: disable CodeReuse/ActiveRecord: `projects` can be array which also responds to pluck
  def load_max_project_member_accesses(projects)
    current_user&.max_member_access_for_project_ids(projects.pluck(:id))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def max_project_member_access(project)
    current_user&.max_member_access_for_project(project.id) || Gitlab::Access::NO_ACCESS
  end

  def max_project_member_access_cache_key(project)
    "access:#{max_project_member_access(project)}"
  end

  def user_status(user)
    return unless user

    unless user.association(:status).loaded?
      exception = RuntimeError.new("Status was not preloaded")
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(exception, user: user.inspect)
    end

    return unless user.status

    content_tag :span,
                class: 'user-status-emoji has-tooltip',
                title: user.status.message_html,
                data: { html: true, placement: 'top' } do
      emoji_icon user.status.emoji
    end
  end

  def impersonation_enabled?
    Gitlab.config.gitlab.impersonation_enabled
  end

  def user_badges_in_admin_section(user)
    [].tap do |badges|
      badges << blocked_user_badge(user) if user.blocked?
      badges << { text: s_('AdminUsers|Admin'), variant: 'success' } if user.admin?
      badges << { text: s_('AdminUsers|External'), variant: 'secondary' } if user.external?
      badges << { text: s_("AdminUsers|It's you!"), variant: nil } if current_user == user
    end
  end

  def work_information(user, with_schema_markup: false)
    return unless user

    organization = user.organization
    job_title = user.job_title

    if organization.present? && job_title.present?
      render_job_title_and_organization(job_title, organization, with_schema_markup: with_schema_markup)
    elsif job_title.present?
      render_job_title(job_title, with_schema_markup: with_schema_markup)
    elsif organization.present?
      render_organization(organization, with_schema_markup: with_schema_markup)
    end
  end

  def can_force_email_confirmation?(user)
    !user.confirmed?
  end

  def user_block_data(user, message)
    {
      path: block_admin_user_path(user),
      method: 'put',
      modal_attributes: {
        title: s_('AdminUsers|Block user %{username}?') % { username: sanitize_name(user.name) },
        messageHtml: message,
        okVariant: 'warning',
        okTitle: s_('AdminUsers|Block')
      }.to_json
    }
  end

  def user_block_effects
    header = tag.p s_('AdminUsers|Blocking user has the following effects:')

    list = tag.ul do
      concat tag.li s_('AdminUsers|User will not be able to login')
      concat tag.li s_('AdminUsers|User will not be able to access git repositories')
      concat tag.li s_('AdminUsers|Personal projects will be left')
      concat tag.li s_('AdminUsers|Owned groups will be left')
    end

    header + list
  end

  private

  def blocked_user_badge(user)
    pending_approval_badge = { text: s_('AdminUsers|Pending approval'), variant: 'info' }
    return pending_approval_badge if user.blocked_pending_approval?

    { text: s_('AdminUsers|Blocked'), variant: 'danger' }
  end

  def get_profile_tabs
    tabs = []

    if can?(current_user, :read_user_profile, @user)
      tabs += [:overview, :activity, :groups, :contributed, :projects, :starred, :snippets]
    end

    tabs
  end

  def trials_link_url
    'https://about.gitlab.com/free-trial/'
  end

  def trials_allowed?(user)
    false
  end

  def get_current_user_menu_items
    items = []

    items << :sign_out if current_user

    return items if current_user&.required_terms_not_accepted?

    items << :help
    items << :profile if can?(current_user, :read_user, current_user)
    items << :settings if can?(current_user, :update_user, current_user)
    items << :start_trial if trials_allowed?(current_user)

    items
  end

  def render_job_title(job_title, with_schema_markup: false)
    if with_schema_markup
      content_tag :span, itemprop: 'jobTitle' do
        job_title
      end
    else
      job_title
    end
  end

  def render_organization(organization, with_schema_markup: false)
    if with_schema_markup
      content_tag :span, itemprop: 'worksFor' do
        organization
      end
    else
      organization
    end
  end

  def render_job_title_and_organization(job_title, organization, with_schema_markup: false)
    if with_schema_markup
      job_title = '<span itemprop="jobTitle">'.html_safe + job_title + "</span>".html_safe
      organization = '<span itemprop="worksFor">'.html_safe + organization + "</span>".html_safe
    end

    html_escape(s_('Profile|%{job_title} at %{organization}')) % { job_title: job_title, organization: organization }
  end
end

UsersHelper.prepend_if_ee('EE::UsersHelper')
