class TimeEntryController
  def create
    if issue_id.present?
      log_time_on_issue
    else
      log_time_on_project
    end
  end

  def log_time_on_project
    log_time(nil, project_id) { do_log_time_on_project }
  end

  def log_time_on_issue
    log_time(issue_id, project_id) { do_log_time_on_issue }
  end

  def do_log_time_on_project
    time_entry = LogTime.new(self).on_project(project_id) respond_to do |format|
      format.html { redirect_success_for_project_time_entry(time_entry) }
      format.api { render_show_status_created }
    end
  end

  def do_log_time_on_issue
    time_entry = LogTime.new(self).on_issue(project_id, issue_id) respond_to do |format|
      format.html { redirect_success_for_issue_time_entry(time_entry) }
      format.api { render_show_status_created(time_entry) }
    end
  end

  def log_time(issue_id, project_id)
    begin
      yield
    rescue LogTime::DataNotFound
      render_404
    rescue LogTime::NotAuthorizedArchivedProject
      render_403 :message => :notice_not_authorized_archived_project
    rescue LogTime::AuthorizationError
      deny_access
    rescue LogTime::ValidationError => e
      respond_to do |format|
        format.html { render_new(e.time_entry, e.project) }
        format.api { render_validation_errors(e.time_entry) }
      end
    end
  end

  class LogTime < SimpleDelegator
    class AuthorizationError < StandardError; end
    class NotAuthorizedArchivedProject < StandardError; end
    class DataNotFound < StandardError; end
    class ValidationError < StandardError
      attr_accessor :time_entry, :project

      def initialize(time_entry, project)
        @time_entry = time_entry
        @project = project
      end
    end

    def initialize(parent)
      super(parent)
    end

    def on_issue(project_id, issue_id)
      project, issue = find_project_and_issue(project_id, issue_id)
      authorize(User.current, project)
      time_entry = new_time_entry_for_issue(issue, project)
      notify_hook(time_entry)
      save(time_entry, project)
      time_entry
    end

    def on_project(project_id)
      project = find_project(project_id)
      authorize(User.current, project)
      time_entry = new_time_entry_for_project(project)
      notify_hook(time_entry)
      save(time_entry, project)
      time_entry
    end
  end
end
