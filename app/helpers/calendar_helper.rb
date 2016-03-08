module CalendarHelper

  def load_projects_for_log(log)
    Project.all.map{|p| [p.project_name, p.id]}
  end

  def load_tasks_for_log(log)
    if log.persisted?
      log.project.project_tasks.map{|p| [p.name, p.task_id]}
    else
      []
    end
  end
end
