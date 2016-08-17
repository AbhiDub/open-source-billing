module CalendarHelper

  def load_projects_for_log
    projects = (current_user.has_role? :staff)? current_user.staff.projects : Project.joins("LEFT OUTER JOIN clients ON clients.id = projects.client_id ")
    projects.unarchived.map{|p| [p.project_name, p.id]}
  end

  def load_projects_for_invoice
    Project.select{|p| p.logs.present?}.map{|p| [p.project_name, p.id]}
  end

  def load_tasks_for_log(log)
    if log.persisted?
      log.project.project_tasks.map{|p| [p.name, p.id]}
    else
      []
    end
  end

  def get_company_id
    session['current_company'] || current_user.current_company || current_user.first_company_id
  end

end
