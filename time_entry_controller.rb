class TimeEntryController

  def create
    @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => User.current.today)
    @time_entry.safe_attributes = params[:time_entry]

    call_hook(:controller_timelog_edit_before_save, {:params => params, :time_entry => @time_entry})

    if @time_entry.save respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_create)
        if params[:continue]
          if params[:project_id]
            options = {
                :time_entry => {
                    :issue_id => @time_entry.issue_id,
                    :activity_id => @time_entry.activity_id
                },
                :back_url => params[:back_url]
            }
            if @time_entry.issue
              redirect_to new_project_issue_time_entry_path(@time_entry.project, @time_entry.issue, options)
            else
              redirect_to new_project_time_entry_path(@time_entry.project, options)
            end
          else
            options = {
                :time_entry => {
                    :project_id => @time_entry.project_id,
                    :issue_id => @time_entry.issue_id,
                    :activity_id => @time_entry.activity_id
                },
                :back_url => params[:back_url]
            }
            redirect_to new_time_entry_path(options)
          end
        else
          redirect_back_or_default project_time_entries_path(@time_entry.project)
        end
      }

      format.api { render :action => 'show', :status => :created, :location => time_entry_url(@time_entry) }
    end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@time_entry) }
      end
    end
  end
end

